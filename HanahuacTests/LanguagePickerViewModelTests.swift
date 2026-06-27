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

    /// Build a picker view model selecting `locale`, off a fresh in-memory store when none is given.
    private func makeViewModel(
        selecting locale: AppLocale,
        store: LanguagePackDownloadStore? = nil
    ) -> LanguagePickerViewModel {
        LanguagePickerViewModel(
            languageManager: makeManager(selecting: locale),
            store: store ?? LanguagePackDownloadStore()
        )
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

    // MARK: - story 011: incremental search (native + English name)

    /// AC1: a query typed in English ("Japanese") surfaces 日本語, AND a query typed in the native
    /// script ("日本") surfaces it too — proving search matches BOTH the native display name and the
    /// English name.
    func testSearch_matchesBothEnglishAndNativeName() {
        let viewModel = makeViewModel(selecting: .en)

        viewModel.query = "Japanese"
        XCTAssertEqual(
            viewModel.filteredRows.map(\.locale),
            [.ja],
            "an English query matches the English name"
        )
        XCTAssertEqual(viewModel.filteredRows.first?.displayName, "日本語")

        viewModel.query = "日本"
        XCTAssertEqual(
            viewModel.filteredRows.map(\.locale),
            [.ja],
            "a native-script substring matches the native display name"
        )
    }

    /// Native-script substring matching works for every non-Latin script the feature ships
    /// (ja/zh-Hans/hi/bn/ar/ur), not just Japanese.
    func testSearch_nativeScriptSubstring_worksForNonLatinScripts() {
        let viewModel = makeViewModel(selecting: .en)
        let cases: [(query: String, expected: AppLocale)] = [
            ("中文", .zhHans),
            ("हिन्दी", .hi),
            ("বাংলা", .bn),
            ("العربية", .ar),
            ("اردو", .ur)
        ]
        for (query, expected) in cases {
            viewModel.query = query
            XCTAssertTrue(
                viewModel.filteredRows.contains { $0.locale == expected },
                "native-script query '\(query)' must surface \(expected.rawValue)"
            )
        }
    }

    /// AC: matching is case- AND diacritic-insensitive — "espanol" (no accent, lowercase) matches
    /// "Español".
    func testSearch_isCaseAndDiacriticInsensitive() {
        let viewModel = makeViewModel(selecting: .en)

        viewModel.query = "espanol"
        let matched = viewModel.filteredRows.map(\.locale)
        XCTAssertTrue(matched.contains(.esMX), "'espanol' folds to match 'Español (México)'")
        XCTAssertTrue(matched.contains(.esES), "'espanol' folds to match 'Español (España)'")

        viewModel.query = "FRENCH"
        XCTAssertEqual(viewModel.filteredRows.map(\.locale), [.fr], "uppercase English query matches")
    }

    /// AC: an empty (or whitespace-only) query shows all 21 languages.
    func testSearch_emptyQuery_showsAllTwentyOne() {
        let viewModel = makeViewModel(selecting: .en)

        XCTAssertEqual(viewModel.filteredRows.count, 21, "empty query → every language shows")

        viewModel.query = "   "
        XCTAssertEqual(viewModel.filteredRows.count, 21, "a whitespace-only query is treated as empty")

        viewModel.query = "definitely-no-such-language"
        XCTAssertTrue(viewModel.filteredRows.isEmpty, "a non-matching query filters everything out")
    }

    // MARK: - story 011: grouped layout (downloaded vs available)

    /// AC2: the picker splits rows into a "downloaded" group (bundled base + already-downloaded packs)
    /// and an "available" group (downloadable / downloading / failed), consistent with ODR state.
    func testGroups_splitDownloadedVsAvailable() throws {
        let store = LanguagePackDownloadStore()
        store.markAvailable(.fr) // a downloaded pack → downloaded group
        store.markDownloading(.de, progress: 0.3) // in flight → available group
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .en), store: store)

        let downloaded = try XCTUnwrap(viewModel.groups.first { $0.kind == .downloaded })
        let available = try XCTUnwrap(viewModel.groups.first { $0.kind == .available })

        let downloadedLocales = downloaded.rows.map(\.locale)
        XCTAssertTrue(downloadedLocales.contains(.en), "bundled base en is downloaded")
        XCTAssertTrue(downloadedLocales.contains(.esMX), "bundled base es-MX is downloaded")
        XCTAssertTrue(downloadedLocales.contains(.fr), "a downloaded pack is in the downloaded group")
        XCTAssertFalse(downloadedLocales.contains(.de), "an in-flight download is NOT yet downloaded")

        let availableLocales = available.rows.map(\.locale)
        XCTAssertTrue(availableLocales.contains(.de), "an in-flight download is in the available group")
        XCTAssertTrue(availableLocales.contains(.ko), "a not-requested pack is available to download")
        XCTAssertFalse(availableLocales.contains(.fr), "a downloaded pack is not in the available group")

        // Every language appears in exactly one group; the union is all 21.
        XCTAssertEqual(downloaded.rows.count + available.rows.count, 21)
        XCTAssertEqual(viewModel.groups.first?.kind, .downloaded, "downloaded section precedes available")
    }

    /// A group with no matching rows is omitted (the picker never draws an empty header). With nothing
    /// downloaded beyond the two bundled bases, narrowing the search to a downloadable-only match yields
    /// only the available group.
    func testGroups_emptyGroupOmittedUnderSearch() {
        let viewModel = makeViewModel(selecting: .en)

        viewModel.query = "French" // fr is a not-downloaded pack → available only
        XCTAssertEqual(viewModel.groups.map(\.kind), [.available], "only the non-empty group is present")
        XCTAssertEqual(viewModel.groups.first?.rows.map(\.locale), [.fr])
    }

    // MARK: - story 011: search + grouping under an RTL locale

    /// AC3: with an RTL language (Arabic) selected, search and grouping still produce correct results —
    /// the view-model projection is layout-direction-independent, so the mirrored UI renders correct
    /// data. (The mirrored *layout* is driven separately by `appLayoutDirection`; this asserts the data
    /// feeding it is right.)
    func testSearchAndGrouping_underRTLSelectedLocale() throws {
        XCTAssertTrue(AppLocale.ar.isRTL, "precondition: ar is an RTL language")
        let store = LanguagePackDownloadStore()
        store.markAvailable(.ar) // the selected RTL pack is downloaded
        let viewModel = LanguagePickerViewModel(languageManager: makeManager(selecting: .ar), store: store)

        // Empty query under RTL still shows all 21, grouped, with the downloaded RTL pack present.
        XCTAssertEqual(viewModel.filteredRows.count, 21)
        let downloaded = try XCTUnwrap(viewModel.groups.first { $0.kind == .downloaded })
        XCTAssertTrue(
            downloaded.rows.contains { $0.locale == .ar && $0.isSelected },
            "the selected, downloaded RTL pack is in the downloaded group and marked selected"
        )

        // Native-script search under RTL surfaces the Arabic row.
        viewModel.query = "العربية"
        XCTAssertEqual(viewModel.filteredRows.map(\.locale), [.ar], "native RTL-script search filters correctly")

        // English search under RTL also works.
        viewModel.query = "Urdu"
        XCTAssertEqual(viewModel.filteredRows.map(\.locale), [.ur])
    }

    // MARK: - story 011: rows carry the English name for search

    func testRows_carryEnglishNameAlongsideNativeDisplayName() throws {
        let viewModel = makeViewModel(selecting: .en)
        let ja = try row(viewModel, .ja)
        XCTAssertEqual(ja.displayName, "日本語", "native display name is unchanged")
        XCTAssertEqual(ja.englishName, "Japanese", "the English name is exposed for search")
    }
}
