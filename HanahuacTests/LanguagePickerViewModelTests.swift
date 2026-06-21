import XCTest
@testable import Hanahuac

/// Drives the language picker's presentation layer (story 005) off a fresh ``LanguagePackDownloadStore``
/// with NO live network:
/// - row rendering for idle/available (bundled base + downloaded), downloading+progress, failed+retry;
/// - selecting a downloadable language triggers the lazy ODR download via the holder seam;
/// - retry re-issues a failed download through the holder seam;
/// - graceful offline degradation (absent pack → non-crashing downloadable/failed row, selection still
///   falls back through the chain);
/// - the carry-over launch reconciliation (task 005) compensating for didSet-on-init omission.
@MainActor
final class LanguagePickerViewModelTests: XCTestCase {
    private var savedProvider: LanguagePackProvider!

    override func setUp() {
        super.setUp()
        savedProvider = LanguagePackProviderHolder.active
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    // MARK: - Test fakes (no live network)

    /// A hand-driven ``ResourceRequesting`` that completes only when the test tells it to.
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

        func emitProgress(_ value: Double) {
            loadingProgress = value
            progressHandler?(value)
        }

        func complete() {
            completion?(nil)
            completion = nil
        }

        func fail() {
            completion?(NSError(domain: "test", code: 1))
            completion = nil
        }
    }

    /// A factory that records every request it hands out.
    private final class FakeFactory {
        private(set) var made: [FakeResourceRequest] = []
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

    /// Spin the run loop briefly so a `Task { @MainActor }` published from a completion handler runs.
    private func drainMainActor() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    private func makeManager(selecting locale: AppLocale) -> LanguageManager {
        let fake = InMemoryKeyValueStore()
        fake.setString(locale.rawValue, forKey: PreferenceKey.appLocale.rawValue)
        return LanguageManager(preferences: KeyValuePreferenceStore(store: fake))
    }

    private func row(_ viewModel: LanguagePickerViewModel, _ locale: AppLocale) throws -> LanguagePickerRow {
        try XCTUnwrap(viewModel.rows.first { $0.locale == locale })
    }

    // MARK: - LanguagePackRowState pure mapping

    func testRowStateMapping_projectsEachDownloadStateAndBaseFlag() {
        XCTAssertEqual(LanguagePackRowState.from(.available, isBase: true), .bundledAvailable)
        XCTAssertEqual(LanguagePackRowState.from(.notRequested, isBase: true), .bundledAvailable)
        XCTAssertEqual(LanguagePackRowState.from(.notRequested, isBase: false), .downloadable)
        XCTAssertEqual(LanguagePackRowState.from(.available, isBase: false), .available)
        XCTAssertEqual(
            LanguagePackRowState.from(.downloading(progress: 0.42), isBase: false),
            .downloading(progress: 0.42)
        )
        XCTAssertEqual(
            LanguagePackRowState.from(.failed(retryable: true), isBase: false),
            .failed(retryable: true)
        )
    }

    // MARK: - rows: idle/available rendering (base + downloaded)

    func testRows_baseLanguagesRenderBundledAvailable() throws {
        let store = LanguagePackDownloadStore()
        let manager = makeManager(selecting: .en)
        let viewModel = LanguagePickerViewModel(languageManager: manager, store: store)

        let en = try row(viewModel, .en)
        XCTAssertEqual(en.state, .bundledAvailable)
        XCTAssertEqual(en.displayName, "English", "row shows the native display name from the catalog")
        XCTAssertTrue(en.isSelected)
        XCTAssertTrue(en.state.isReady)

        let esMX = try row(viewModel, .esMX)
        XCTAssertEqual(esMX.state, .bundledAvailable, "es-MX is a bundled base language too")
    }

    func testRows_downloadablePackNotRequestedRendersDownloadable() throws {
        let store = LanguagePackDownloadStore()
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        let fr = try row(viewModel, .fr)
        XCTAssertEqual(fr.state, .downloadable)
        XCTAssertFalse(fr.state.isReady, "a not-yet-downloaded pack is not ready/selectable as available")
        XCTAssertNil(fr.state.downloadProgress)
    }

    func testRows_downloadedPackRendersAvailable() throws {
        let store = LanguagePackDownloadStore()
        store.markAvailable(.fr)
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        let fr = try row(viewModel, .fr)
        XCTAssertEqual(fr.state, .available, "an already-downloaded pack renders available, no re-download")
        XCTAssertTrue(fr.state.isReady)
    }

    // MARK: - rows: downloading + progress

    func testRows_downloadingSurfacesFractionalProgress() throws {
        let store = LanguagePackDownloadStore()
        store.markDownloading(.de, progress: 0.25)
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        let de = try row(viewModel, .de)
        XCTAssertEqual(de.state, .downloading(progress: 0.25))
        XCTAssertEqual(de.state.downloadProgress, 0.25, "the determinate progress fraction is surfaced")
        XCTAssertFalse(de.state.isReady)
    }

    // MARK: - rows: failed + retry

    func testRows_failedRendersRetryableFailure() throws {
        let store = LanguagePackDownloadStore()
        store.markFailed(.ko, retryable: true)
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        let ko = try row(viewModel, .ko)
        XCTAssertEqual(ko.state, .failed(retryable: true))
        XCTAssertTrue(ko.state.canRetry, "a retryable failure exposes the retry affordance")
        XCTAssertFalse(ko.state.isReady)
    }

    // MARK: - selecting a downloadable language triggers the lazy download

    func testSelect_downloadableLanguage_triggersDownloadAndSwitchesSelection() throws {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let manager = makeManager(selecting: .en)
        let viewModel = LanguagePickerViewModel(languageManager: manager, store: store)

        viewModel.select(.fr)

        XCTAssertEqual(manager.current, .fr, "selecting switches the active language")
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0), "selecting kicks off the ODR download")
        let request = try XCTUnwrap(factory.last)
        XCTAssertEqual(request.tags, ["lang-fr"], "request keyed off the language's ODR tag")

        // The picker now renders the in-flight download for that row.
        let fr = try row(viewModel, .fr)
        XCTAssertEqual(fr.state, .downloading(progress: 0))
        XCTAssertTrue(fr.isSelected)
    }

    func testSelect_baseLanguage_issuesNoDownload() {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .fr), store: store)
        viewModel.select(.esMX)

        XCTAssertTrue(factory.made.isEmpty, "selecting a bundled base language never issues an ODR request")
    }

    // MARK: - retry re-issues the download through the holder seam

    func testRetry_reissuesFailedDownload() async throws {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        let provider = LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        // Drive a failure first.
        provider.requestDownload(for: .de)
        let first = try XCTUnwrap(factory.last)
        first.fail()
        await drainMainActor()
        XCTAssertEqual(try row(viewModel, .de).state, .failed(retryable: true))

        // Retry through the view model re-issues a fresh request and the row returns to downloading.
        viewModel.retry(.de)
        XCTAssertEqual(store.state(for: .de), .downloading(progress: 0))
        let second = try XCTUnwrap(factory.last)
        XCTAssertNotIdentical(second, first, "retry issues a fresh request")
        XCTAssertEqual(try row(viewModel, .de).state, .downloading(progress: 0))
    }

    // MARK: - graceful offline degradation: absent pack, selection falls back through the chain

    func testOffline_absentPack_rendersNonCrashingRow_andSelectionFallsBackThroughChain() throws {
        // ODR provider active, nothing downloaded — simulates offline with the pack absent.
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        let provider = LanguagePackBootstrap.install(store: store, makeRequest: factory.make)
        // Mark a failure so the row communicates the unavailable/failed state rather than crashing.
        store.markFailed(.nah, retryable: true)

        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .nah), store: store)

        let nah = try row(viewModel, .nah)
        XCTAssertEqual(nah.state, .failed(retryable: true), "absent/failed pack yields a non-crashing failed row")

        // The provider degrades string resolution through the fallback chain (nah → es-MX → en) without
        // crashing, even with no pack present.
        XCTAssertEqual(
            L10n.string("__definitely_missing_key__", locale: .nah),
            "__definitely_missing_key__",
            "offline resolution with an absent pack terminates on the key, never crashes"
        )
        _ = provider.state(for: .nah)
    }

    // MARK: - carry-over launch reconciliation (task 005 / 009)

    func testReconcile_persistedDownloadableSelection_triggersDownloadAtLaunch() {
        // LanguageManager.init restores a persisted downloadable selection by assigning `current`
        // directly, which does NOT fire its didSet — so the ODR download is never kicked off at launch.
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let manager = makeManager(selecting: .fr)
        XCTAssertEqual(manager.current, .fr, "selection restored from persistence")
        XCTAssertTrue(factory.made.isEmpty, "init's direct assignment did not fire didSet, so no download yet")
        XCTAssertEqual(store.state(for: .fr), .notRequested)

        let viewModel = LanguagePickerViewModel(languageManager: manager, store: store)

        // The picker's appear hook compensates for the missing didSet.
        viewModel.reconcileSelectedDownloadOnAppear()

        XCTAssertEqual(factory.made.count, 1, "reconcile (re-)triggers the ODR download for the restored selection")
        XCTAssertEqual(store.state(for: .fr), .downloading(progress: 0), "store transitions to downloading")
    }

    func testReconcile_baseLanguageSelection_isNoOp() {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .esMX), store: store)
        viewModel.reconcileSelectedDownloadOnAppear()

        XCTAssertTrue(factory.made.isEmpty, "a restored base-language selection needs no download")
    }

    func testReconcile_alreadyAvailablePack_isNoOp() {
        let factory = FakeFactory()
        let store = LanguagePackDownloadStore()
        store.markAvailable(.de)
        LanguagePackBootstrap.install(store: store, makeRequest: factory.make)

        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .de), store: store)
        viewModel.reconcileSelectedDownloadOnAppear()

        XCTAssertTrue(factory.made.isEmpty, "an already-available pack is not re-downloaded on appear")
    }
}
