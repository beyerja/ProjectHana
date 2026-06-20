import XCTest
@testable import Hanahuac

/// Drives the ODR provider and its download state machine end to end with a ``FakeResourceRequest``
/// (NO live network):
/// - request → progress → success exposes the downloaded geo data and flips `state(for:)` to
///   `available`;
/// - request → failure surfaces `failed(retryable:)`, then `retry` re-issues the request;
/// - an absent/failed pack falls through the chain to bundled base names;
/// - base languages are NEVER requested and always report `available`;
/// - offline-with-zero-packs resolution is unchanged.
@MainActor
final class ODRLanguagePackProviderTests: XCTestCase {
    private var savedProvider: LanguagePackProvider!

    override func setUp() {
        super.setUp()
        savedProvider = LanguagePackProviderHolder.active
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    // MARK: - Test fake

    /// A hand-driven ``ResourceRequesting`` that records lifecycle calls and completes only when the
    /// test tells it to — no real `NSBundleResourceRequest`, no network.
    private final class FakeResourceRequest: ResourceRequesting {
        let tags: Set<String>
        var loadingProgress: Double = 0
        private(set) var beginCount = 0
        private(set) var didEnd = false
        var alreadyPresent = false
        private var completion: ((Error?) -> Void)?
        private var progressHandler: ((Double) -> Void)?

        init(tags: Set<String>) {
            self.tags = tags
        }

        func observeProgress(_ handler: @escaping (Double) -> Void) {
            progressHandler = handler
        }

        func conditionallyBeginAccessingResources(completionHandler: @escaping (Bool) -> Void) {
            completionHandler(alreadyPresent)
        }

        func beginAccessingResources(completionHandler: @escaping (Error?) -> Void) {
            beginCount += 1
            completion = completionHandler
        }

        func endAccessingResources() {
            didEnd = true
        }

        /// Drive a progress update the way ODR's KVO would: update the value AND fire the observer the
        /// provider registered via ``observeProgress(_:)``.
        func emitProgress(_ value: Double) {
            loadingProgress = value
            progressHandler?(value)
        }

        /// Complete the in-flight access with success.
        func complete() {
            completion?(nil)
            completion = nil
        }

        /// Complete the in-flight access with a synthetic error.
        func fail() {
            completion?(NSError(domain: "test", code: 1))
            completion = nil
        }
    }

    /// A factory that hands out (and records) ``FakeResourceRequest``s keyed by their tag set.
    private final class FakeFactory {
        private(set) var made: [FakeResourceRequest] = []
        /// Applied to every request this factory hands out, so a test can simulate resources that are
        /// already present on device (the conditional fast path).
        var alreadyPresent = false

        func make(_ tags: Set<String>) -> ResourceRequesting {
            let request = FakeResourceRequest(tags: tags)
            request.alreadyPresent = alreadyPresent
            made.append(request)
            return request
        }

        var last: FakeResourceRequest? {
            made.last
        }
    }

    private func makeProvider(
        factory: FakeFactory
    ) -> (ODRLanguagePackProvider, LanguagePackDownloadStore) {
        let store = LanguagePackDownloadStore()
        let provider = ODRLanguagePackProvider(
            downloadStore: store,
            makeRequest: factory.make
        )
        return (provider, store)
    }

    /// Spin the run loop briefly so a `Task { @MainActor }` published from a completion handler runs.
    private func drainMainActor() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    // MARK: - request → progress → success

    func testRequest_progress_success_flipsStateAndExposesData() async throws {
        let factory = FakeFactory()
        let (provider, store) = makeProvider(factory: factory)

        XCTAssertEqual(provider.state(for: .fr), .notDownloaded, "no pack requested yet")

        provider.requestDownload(for: .fr)
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0))
        XCTAssertEqual(provider.state(for: .fr), .downloading)
        let request = try XCTUnwrap(factory.last)
        XCTAssertEqual(request.tags, ["lang-fr"], "request keyed off the language's ODR tag")
        XCTAssertEqual(request.beginCount, 1)

        request.emitProgress(0.5)
        await drainMainActor()
        XCTAssertEqual(
            store.state(for: .fr),
            .downloading(progress: 0.5),
            "progress observed on the seam is forwarded to the store"
        )

        request.complete()
        await drainMainActor()

        XCTAssertEqual(store.state(for: .fr), .available)
        XCTAssertEqual(provider.state(for: .fr), .available)
    }

    // MARK: - intermediate progress is forwarded to the store

    func testProgressObservation_forwardsIntermediateValuesToStore() async throws {
        let factory = FakeFactory()
        let (provider, store) = makeProvider(factory: factory)

        provider.requestDownload(for: .fr)
        let request = try XCTUnwrap(factory.last)

        for value in [0.1, 0.4, 0.85] {
            request.emitProgress(value)
            await drainMainActor()
            XCTAssertEqual(
                store.state(for: .fr),
                .downloading(progress: value),
                "intermediate progress \(value) must be wired through to the store"
            )
        }

        request.complete()
        await drainMainActor()
        XCTAssertEqual(store.state(for: .fr), .available)
    }

    // MARK: - already-present resources take the fast path

    func testConditionallyBeginAccessing_alreadyPresent_skipsDownloadAndResolves() async throws {
        let factory = FakeFactory()
        // Resources already on device → the conditional check completes with `true`.
        factory.alreadyPresent = true
        let (provider, _) = makeProvider(factory: factory)

        provider.requestDownload(for: .fr)
        await drainMainActor()

        let request = try XCTUnwrap(factory.last)
        XCTAssertEqual(request.beginCount, 0, "already-present resources skip beginAccessingResources")
        XCTAssertEqual(provider.state(for: .fr), .available, "fast path resolves straight to available")
    }

    // MARK: - request → failure → retry

    func testRequest_failure_surfacesFailed_thenRetryReissues() async throws {
        let factory = FakeFactory()
        let (provider, store) = makeProvider(factory: factory)

        provider.requestDownload(for: .de)
        let first = try XCTUnwrap(factory.last)
        first.fail()
        await drainMainActor()

        XCTAssertEqual(store.state(for: .de), .failed(retryable: true))
        XCTAssertEqual(provider.state(for: .de), .failed)
        XCTAssertTrue(first.didEnd, "a failed request is ended/released")

        provider.retryDownload(for: .de)
        XCTAssertEqual(store.state(for: .de), .downloading(progress: 0))
        let second = try XCTUnwrap(factory.last)
        XCTAssertNotIdentical(second, first, "retry issues a fresh request")
        XCTAssertEqual(second.beginCount, 1)

        second.complete()
        await drainMainActor()
        XCTAssertEqual(provider.state(for: .de), .available)
    }

    // MARK: - duplicate requests coalesce

    func testDuplicateRequests_coalesceToOneInFlight() {
        let factory = FakeFactory()
        let (provider, _) = makeProvider(factory: factory)

        provider.requestDownload(for: .fr)
        provider.requestDownload(for: .fr)
        XCTAssertEqual(factory.made.count, 1, "a second request while in flight is coalesced")
    }

    // MARK: - release clears in-flight state; a late completion cannot repopulate

    func testRelease_clearsInFlight_andLateCompletionDoesNotRepopulate() async throws {
        let factory = FakeFactory()
        let (provider, store) = makeProvider(factory: factory)

        provider.requestDownload(for: .fr)
        let request = try XCTUnwrap(factory.last)

        // Tear down while the request is still in flight.
        provider.release()

        // A late completion from the already-released request must not repopulate any state.
        request.complete()
        await drainMainActor()

        XCTAssertNotEqual(provider.state(for: .fr), .available, "late completion after release is dropped")
        XCTAssertNotEqual(store.state(for: .fr), .available, "store is not flipped by a post-release completion")
        XCTAssertTrue(request.didEnd, "the late request is released so the OS can purge it")
    }

    // MARK: - base languages are never requested

    func testBaseLanguages_areNeverRequested_andAlwaysAvailable() {
        let factory = FakeFactory()
        let (provider, _) = makeProvider(factory: factory)

        for base in [AppLocale.en, .esMX] {
            provider.requestDownload(for: base)
            XCTAssertEqual(provider.state(for: base), .available)
        }
        XCTAssertTrue(factory.made.isEmpty, "base languages must never issue an ODR request")
    }

    // MARK: - absent pack falls through the chain to bundled base

    func testAbsentPack_resolutionFallsThroughToBundledBase() {
        let factory = FakeFactory()
        let (provider, _) = makeProvider(factory: factory)
        // Make the ODR provider active WITHOUT downloading anything.
        LanguagePackProviderHolder.active = provider

        let country = Country(
            id: "ZZ",
            name: "Base Name",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            nameKo: nil,
            nameNah: nil,
            capital: "Base City",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            capitalKo: nil,
            capitalNah: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )
        // No pack downloaded → fr/de/ko/nah all degrade to the bundled base name, app stays usable.
        for locale in AppLocale.allCases {
            XCTAssertEqual(
                country.localizedName(for: locale),
                "Base Name",
                "absent pack for \(locale.rawValue) degrades to bundled base"
            )
        }
    }

    // MARK: - offline with zero packs: L10n unchanged

    func testOfflineZeroPacks_l10nTerminatesOnKey() {
        let factory = FakeFactory()
        let (provider, _) = makeProvider(factory: factory)
        LanguagePackProviderHolder.active = provider

        XCTAssertEqual(
            L10n.string("__definitely_missing_key__", locale: .ko),
            "__definitely_missing_key__",
            "offline with zero packs still terminates on the raw key, never crashes"
        )
    }
}
