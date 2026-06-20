import Foundation

/// Production composition root for the downloadable-language-packs feature.
///
/// Without this, the app would keep the default ``BundledLanguagePackProvider`` as
/// ``LanguagePackProviderHolder/active``, and ``LanguagePackProviderHolder/requestDownloadIfNeeded(for:)``
/// (called from ``LanguageManager/current``'s `didSet`) would downcast `active as? ODRLanguagePackProvider`
/// to `nil` — so selecting a downloadable language (fr/de/ko/nah) would never trigger an ODR download.
/// This installs a single ``ODRLanguagePackProvider``, backed by the **shared** observable
/// ``LanguagePackDownloadStore``, as the active provider at launch, satisfying story 004's acceptance
/// criterion that selecting a not-yet-downloaded language triggers a lazy ODR download.
///
/// ## Shared download store
/// The provider is wired to ``LanguagePackDownloadStore/shared`` — the SAME instance the language
/// picker (story 005) observes — so the picker renders the live per-language download state the ODR
/// provider mutates. The picker reaches it via this singleton (mirroring ``LanguageManager/shared`` and
/// the `SyncCoordinator` patterns).
///
/// ## Testability
/// ``install(store:makeRequest:)`` is injectable: a test can call it with a fresh store and a fake
/// ``ResourceRequestFactory`` to verify the holder install drives the ODR download path (the downcast is
/// no longer `nil`) with no live network. ``HanahuacApp`` calls ``installForProduction()`` at launch,
/// which wires the shared store and the live `NSBundleResourceRequest` factory.
@MainActor
enum LanguagePackBootstrap {
    /// Install an ``ODRLanguagePackProvider`` as the active provider, backed by `store` and `makeRequest`.
    ///
    /// Returns the installed provider so a caller (or test) can drive/inspect it. Idempotent in effect:
    /// calling it again simply swaps in a new provider over the same (or a different) store.
    ///
    /// - Parameters:
    ///   - store: the observable download-state store the provider mutates and the picker observes.
    ///     Defaults to the shared singleton so production and the picker share one instance.
    ///   - makeRequest: the resource-request factory. Defaults to the live `NSBundleResourceRequest`
    ///     factory; tests inject a fake to avoid any live network.
    /// - Returns: the installed ``ODRLanguagePackProvider``.
    @discardableResult
    static func install(
        store: LanguagePackDownloadStore = .shared,
        makeRequest: @escaping ResourceRequestFactory = LiveResourceRequest.factory
    ) -> ODRLanguagePackProvider {
        let provider = ODRLanguagePackProvider(downloadStore: store, makeRequest: makeRequest)
        LanguagePackProviderHolder.active = provider
        return provider
    }

    /// The launch-time install used by ``HanahuacApp``: wires the shared store and the live ODR factory.
    ///
    /// Skips installation under XCTest so the holder keeps its ``BundledLanguagePackProvider`` default
    /// for the many tests that rely on it (the unit-test host instantiates `@main HanahuacApp`, running
    /// this at process start). Tests that exercise the ODR path call ``install(store:makeRequest:)``
    /// directly with a fake factory, so this guard never hides the production behavior under test.
    static func installForProduction() {
        guard !isRunningTests else {
            return
        }
        install()
    }

    /// `true` when running inside the XCTest host, detected via the test-bundle configuration the test
    /// runner injects into the environment. Used to keep the default bundled provider active for tests.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
