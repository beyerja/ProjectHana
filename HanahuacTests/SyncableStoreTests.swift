import XCTest
@testable import Hanahuac

final class SyncableStoreTests: XCTestCase {
    // MARK: - KeyValueActiveSetStore over the in-memory fake (stands in for ubiquitous backend)

    func testActiveSetRoundTripsThroughKeyValueStore() {
        let fake = InMemoryKeyValueStore()
        let store: ActiveSetStore = KeyValueActiveSetStore(store: fake, language: AppLocale.en.rawValue)

        store.save(["a", "b", "c"], for: .country)
        XCTAssertEqual(store.load(for: .country), ["a", "b", "c"])

        store.clear(for: .country)
        XCTAssertEqual(store.load(for: .country), [])
    }

    func testActiveSetKeySchemeMatchesUserDefaultsImplementation() {
        // Both implementations must use the same per-language key so local data is read transparently
        // when the backend is swapped. Write with the KeyValue store and confirm the raw key, which is
        // namespaced by language (`activeSet.<language>.<category>`).
        let fake = InMemoryKeyValueStore()
        let store = KeyValueActiveSetStore(store: fake, language: AppLocale.en.rawValue)
        store.save(["x"], for: .river)
        XCTAssertEqual(fake.stringArray(forKey: "activeSet.en.river"), ["x"])
    }

    func testActiveSetIsolatedPerCategory() {
        let store = KeyValueActiveSetStore(store: InMemoryKeyValueStore(), language: AppLocale.en.rawValue)
        store.save(["c1"], for: .country)
        store.save(["r1", "r2"], for: .river)
        XCTAssertEqual(store.load(for: .country), ["c1"])
        XCTAssertEqual(store.load(for: .river), ["r1", "r2"])
        XCTAssertEqual(store.load(for: .mountain), [])
    }

    func testActiveSetIsolatedPerLanguage() throws {
        // Two stores over the same backend but different languages must not see each other's set.
        let suite = try XCTUnwrap(UserDefaults(suiteName: "test.activeset.lang.\(UUID().uuidString)"))
        let en = UserDefaultsActiveSetStore(language: AppLocale.en.rawValue, defaults: suite)
        let ko = UserDefaultsActiveSetStore(language: AppLocale.ko.rawValue, defaults: suite)

        en.save(["us", "fr"], for: .country)
        ko.save(["kr"], for: .country)

        XCTAssertEqual(en.load(for: .country), ["us", "fr"])
        XCTAssertEqual(ko.load(for: .country), ["kr"], "Korean active set is independent of English")

        // Switching back to English restores its set exactly.
        let enAgain = UserDefaultsActiveSetStore(language: AppLocale.en.rawValue, defaults: suite)
        XCTAssertEqual(enAgain.load(for: .country), ["us", "fr"])
    }

    // MARK: - UserDefaults fallback still round-trips

    func testUserDefaultsActiveSetStoreStillRoundTrips() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "test.activeset.\(UUID().uuidString)"))
        let store: ActiveSetStore = UserDefaultsActiveSetStore(language: AppLocale.en.rawValue, defaults: suite)
        store.save(["a", "b"], for: .sea)
        XCTAssertEqual(store.load(for: .sea), ["a", "b"])
        store.clear(for: .sea)
        XCTAssertEqual(store.load(for: .sea), [])
    }

    // MARK: - PreferenceStore

    func testPreferenceStoreRoundTrips() {
        let prefs: PreferenceStore = KeyValuePreferenceStore(store: InMemoryKeyValueStore())
        XCTAssertNil(prefs.string(forKey: .appLocale))
        prefs.setString("fr", forKey: .appLocale)
        XCTAssertEqual(prefs.string(forKey: .appLocale), "fr")
    }

    func testPreferenceKeyMatchesHistoricalUserDefaultsKey() {
        XCTAssertEqual(PreferenceKey.appLocale.rawValue, "appLocale")
    }

    // MARK: - LanguageManager uses the injected store

    func testLanguageManagerPersistsThroughInjectedStore() {
        let fake = InMemoryKeyValueStore()
        let prefs = KeyValuePreferenceStore(store: fake)
        let manager = LanguageManager(preferences: prefs)

        manager.current = .fr
        XCTAssertEqual(fake.string(forKey: "appLocale"), "fr")
    }

    func testLanguageManagerRestoresSelectionFromInjectedStore() {
        let fake = InMemoryKeyValueStore()
        fake.setString(AppLocale.de.rawValue, forKey: "appLocale")
        let manager = LanguageManager(preferences: KeyValuePreferenceStore(store: fake))
        XCTAssertEqual(manager.current, .de)
    }

    func testSwappingBackendKeepsObservableAPIIdentical() throws {
        // The same operations against local vs sync-capable backends are observationally identical.
        let local = try KeyValueActiveSetStore(
            store: UserDefaultsKeyValueStore(
                defaults: XCTUnwrap(UserDefaults(suiteName: "test.swap.\(UUID().uuidString)"))
            ),
            language: AppLocale.en.rawValue
        )
        let sync = KeyValueActiveSetStore(store: InMemoryKeyValueStore(), language: AppLocale.en.rawValue)
        for store in [local, sync] as [ActiveSetStore] {
            store.save(["p", "q"], for: .mountain)
            XCTAssertEqual(store.load(for: .mountain), ["p", "q"])
        }
    }
}
