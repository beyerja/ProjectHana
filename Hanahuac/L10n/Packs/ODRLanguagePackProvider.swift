import Foundation

/// The On-Demand-Resources ``LanguagePackProvider``: lazily downloads a non-base language's pack via
/// `NSBundleResourceRequest` (behind the ``ResourceRequesting`` seam) the first time that language is
/// selected, then serves the downloaded `.lproj` bundle and geo-name JSON for it.
///
/// ## Composition
/// Base languages (en, es-MX) are NEVER downloaded: every call for a base language delegates to the
/// wrapped ``BundledLanguagePackProvider`` and reports ``LanguagePackState/available``. Downloadable
/// languages (fr, de, ko, nah) are served from a downloaded pack once present, and otherwise report
/// the download state and resolve to `nil`/the bundled string bundle so the resolver walks the
/// fallback chain (selected → es-MX for ko/nah → en). The app stays fully usable offline with zero
/// packs downloaded.
///
/// ## Concurrency
/// The synchronous seam methods (`stringBundle`/`geoNameData`/`state`) are called from any thread, so
/// the downloaded-pack cache and retained requests are guarded by an `NSLock`. The observable
/// ``LanguagePackDownloadStore`` is `@MainActor`; this provider hops to the main actor to read/mutate
/// it. ODR completion handlers fire off the main thread, so they update the lock-guarded cache first
/// (making the pack immediately resolvable) and then hop to the main actor to publish the state.
///
/// ## Safety
/// Packs are DATA-ONLY: integrity is inherited from App Store code-signing of ODR. There is NO custom
/// network/crypto/signature/hash verification here. Downloaded geo JSON is schema-validated by
/// ``GeoNamePackLoader``; a validation failure degrades safely (state → `failed`, geo data → `nil`).
final class ODRLanguagePackProvider: LanguagePackProvider {
    /// One downloadable language's resolved, downloaded resources.
    private struct ResolvedPack {
        let bundle: Bundle
        let geoData: GeoNamePackData?
        /// Retained for the pack's lifetime so the OS keeps the ODR content on device. Ended on
        /// ``ODRLanguagePackProvider/release()``.
        let request: ResourceRequesting
    }

    /// The always-available bundled provider, used for base languages and as the string-bundle
    /// fallback for not-yet-downloaded packs.
    private let bundled: BundledLanguagePackProvider

    /// The observable per-language download state the picker (story 005) renders. `@MainActor`.
    let downloadStore: LanguagePackDownloadStore

    /// Produces a ``ResourceRequesting`` for a tag set. Production wires ``LiveResourceRequest``;
    /// tests inject a fake.
    private let makeRequest: ResourceRequestFactory

    /// Lock guarding ``resolvedByCode`` and ``inFlightCodes`` for thread-safe synchronous reads.
    private let lock = NSLock()

    /// Downloaded packs keyed by ``AppLocale/rawValue``. Populated on successful download.
    private var resolvedByCode: [String: ResolvedPack] = [:]

    /// Language codes with an in-flight request, to coalesce duplicate `requestDownload` calls.
    private var inFlightCodes: Set<String> = []

    /// Set once ``release()`` tears the provider down, so a late completion from an already-released
    /// request cannot repopulate ``resolvedByCode`` / ``inFlightCodes`` after teardown.
    private var isReleased = false

    /// - Parameters:
    ///   - bundled: the wrapped bundled provider for base languages / fallback.
    ///   - downloadStore: the observable state store (defaults to a fresh one).
    ///   - makeRequest: the resource-request factory (defaults to the live `NSBundleResourceRequest`).
    init(
        bundled: BundledLanguagePackProvider = BundledLanguagePackProvider(),
        downloadStore: LanguagePackDownloadStore,
        makeRequest: @escaping ResourceRequestFactory = LiveResourceRequest.factory
    ) {
        self.bundled = bundled
        self.downloadStore = downloadStore
        self.makeRequest = makeRequest
    }

    // MARK: - LanguagePackProvider

    func stringBundle(for locale: AppLocale) -> Bundle {
        if locale.isBundledBaseLanguage {
            return bundled.stringBundle(for: locale)
        }
        if let resolved = withLock({ resolvedByCode[locale.rawValue] }) {
            return resolved.bundle
        }
        // Pack not downloaded yet: hand back the bundled fallback bundle so `L10n` can walk the chain.
        return bundled.stringBundle(for: locale)
    }

    func geoNameData(for locale: AppLocale) -> GeoNamePackData? {
        if locale.isBundledBaseLanguage {
            return bundled.geoNameData(for: locale)
        }
        // A downloaded pack's geo data, or `nil` so the resolver falls through the chain.
        return withLock {
            resolvedByCode[locale.rawValue]?.geoData
        }
    }

    func state(for locale: AppLocale) -> LanguagePackState {
        if locale.isBundledBaseLanguage {
            // Base languages always ship in the app.
            return .available
        }
        if withLock({ resolvedByCode[locale.rawValue] != nil }) {
            return .available
        }
        // Project the observable download state onto the seam's `LanguagePackState`. The store is
        // `@MainActor`; if we are already on the main thread read it directly, otherwise fall back to
        // `notDownloaded` (the resolver treats that identically to "no pack yet").
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                downloadStore.state(for: locale).mappedToPackState
            }
        }
        return .notDownloaded
    }

    // MARK: - Download triggering & retry

    /// Lazily kick off the ODR download for `locale` the first time it is selected (no-op for base
    /// languages, already-downloaded packs, or an in-flight request). Safe to call repeatedly.
    @MainActor
    func requestDownload(for locale: AppLocale) {
        guard !locale.isBundledBaseLanguage else {
            return
        }
        let code = locale.rawValue
        let tags = locale.odrTags
        guard !tags.isEmpty else {
            return
        }
        let shouldStart: Bool = withLock {
            guard resolvedByCode[code] == nil, !inFlightCodes.contains(code) else {
                return false
            }
            inFlightCodes.insert(code)
            return true
        }
        guard shouldStart else {
            return
        }
        downloadStore.markDownloading(locale, progress: 0)
        beginDownload(for: locale, tags: tags)
    }

    /// Re-issue a previously failed download. Resets the in-flight guard and starts over.
    @MainActor
    func retryDownload(for locale: AppLocale) {
        withLock {
            inFlightCodes.remove(locale.rawValue)
        }
        requestDownload(for: locale)
    }

    /// End all retained `NSBundleResourceRequest`s, letting the OS purge the on-demand resources.
    /// Call on teardown when the downloaded packs are no longer needed. Also clears the in-flight
    /// guard and latches ``isReleased`` so a late completion from an in-flight request cannot
    /// repopulate state after teardown.
    func release() {
        let requests: [ResourceRequesting] = withLock {
            let all = resolvedByCode.values.map(\.request)
            resolvedByCode.removeAll()
            inFlightCodes.removeAll()
            isReleased = true
            return all
        }
        for request in requests {
            request.endAccessingResources()
        }
    }

    // MARK: - Private

    /// Issue the actual ODR request, observe progress, and complete by resolving the pack or marking
    /// the download failed. Takes the fast path when the tagged resources are already on device,
    /// otherwise observes `fractionCompleted` and forwards it to the store. Runs the completion off the
    /// main thread (as ODR does) then publishes to the `@MainActor` store.
    private func beginDownload(for locale: AppLocale, tags: Set<String>) {
        let request = makeRequest(tags)
        request.conditionallyBeginAccessingResources { [weak self] alreadyPresent in
            guard let self else {
                request.endAccessingResources()
                return
            }
            if alreadyPresent {
                // Fast path: resources already on device, no download needed.
                finishSucceeded(locale, request: request)
            } else {
                startDownloading(locale, request: request)
            }
        }
    }

    /// Kick off the actual download (resources are not already present), forwarding fractional progress
    /// to the store as it advances and resolving/failing on completion.
    private func startDownloading(_ locale: AppLocale, request: ResourceRequesting) {
        request.observeProgress { [downloadStore] fraction in
            Task { @MainActor in
                downloadStore.updateProgress(locale, progress: fraction)
            }
        }
        request.beginAccessingResources { [weak self] error in
            guard let self else {
                request.endAccessingResources()
                return
            }
            if let error {
                finishFailed(locale, error: error, request: request)
            } else {
                finishSucceeded(locale, request: request)
            }
        }
    }

    /// On success: resolve the downloaded `.lproj` bundle and decode+validate the geo JSON, cache the
    /// resolved pack (so synchronous reads see it immediately), then publish `available`. A validation
    /// failure of the downloaded JSON degrades safely to `failed` with the request released.
    private func finishSucceeded(_ locale: AppLocale, request: ResourceRequesting) {
        let bundle = downloadedBundle(for: locale)
        let geoData = downloadedGeoData(for: locale, in: bundle)
        let resolved = ResolvedPack(bundle: bundle, geoData: geoData, request: request)
        let didStore: Bool = withLock {
            guard !isReleased else {
                return false
            }
            resolvedByCode[locale.rawValue] = resolved
            inFlightCodes.remove(locale.rawValue)
            return true
        }
        guard didStore else {
            // Provider was released while this download was in flight: drop the late result so it
            // cannot repopulate state, and release the request the OS would otherwise keep retained.
            request.endAccessingResources()
            return
        }
        Task { @MainActor [downloadStore] in
            downloadStore.markAvailable(locale)
        }
    }

    /// On failure (download error): release the request, clear the in-flight guard, and publish a
    /// retryable failure so the picker can offer retry and the resolver degrades to the chain.
    private func finishFailed(_ locale: AppLocale, error _: Error, request: ResourceRequesting) {
        request.endAccessingResources()
        withLock {
            inFlightCodes.remove(locale.rawValue)
        }
        Task { @MainActor [downloadStore] in
            downloadStore.markFailed(locale, retryable: true)
        }
    }

    /// Resolve the downloaded language's `.lproj` bundle. With ODR the resources merge into the main
    /// bundle once accessed, so the language's `.lproj` becomes resolvable exactly as a bundled one;
    /// reuse the bundled provider's resolution.
    private func downloadedBundle(for locale: AppLocale) -> Bundle {
        bundled.stringBundle(for: locale)
    }

    /// Decode and schema-validate the downloaded geo JSON for `locale`. Returns `nil` (degrade safely)
    /// when the JSON resource is absent, malformed, or fails validation — the resolver then walks the
    /// fallback chain. The resource is named `<code>-geo.json` by convention.
    private func downloadedGeoData(for locale: AppLocale, in bundle: Bundle) -> GeoNamePackData? {
        let resourceName = "\(locale.rawValue)-geo"
        guard let url = bundle.url(forResource: resourceName, withExtension: "json")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
            return nil
        }
        return GeoNamePackLoader.decodeOrNil(data)
    }

    /// Run `body` while holding ``lock``.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }
        return body()
    }
}
