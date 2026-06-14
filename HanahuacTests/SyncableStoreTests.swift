import XCTest
@testable import Hanahuac

final class SyncableStoreTests: XCTestCase {

    // MARK: - KeyValueActiveSetStore over the in-memory fake (stands in for ubiquitous backend)

    func testActiveSetRoundTripsThroughKeyValueStore() {
        let fake = InMemoryKeyValueStore()
        let store: ActiveSetStore = KeyValueActiveSetStore(store: fake)

        store.save(["a", "b", "c"], for: .country)
        XCTAssertEqual(store.load(for: .country), ["a", "b", "c"])

        store.clear(for: .country)
        XCTAssertEqual(store.load(for: .country), [])
    }

    func testActiveSetKeySchemeMatchesUserDefaultsImplementation() {
        // Both implementations must use the same key so local data is read transparently when
        // the backend is swapped. Write with the KeyValue store and confirm the raw key.
        let fake = InMemoryKeyValueStore()
        let store = KeyValueActiveSetStore(store: fake)
        store.save(["x"], for: .river)
        XCTAssertEqual(fake.stringArray(forKey: "activeSet.river"), ["x"])
    }

    func testActiveSetIsolatedPerCategory() {
        let store = KeyValueActiveSetStore(store: InMemoryKeyValueStore())
        store.save(["c1"], for: .country)
        store.save(["r1", "r2"], for: .river)
        XCTAssertEqual(store.load(for: .country), ["c1"])
        XCTAssertEqual(store.load(for: .river), ["r1", "r2"])
        XCTAssertEqual(store.load(for: .mountain), [])
    }

    // MARK: - UserDefaults fallback still round-trips

    func testUserDefaultsActiveSetStoreStillRoundTrips() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "test.activeset.\(UUID().uuidString)"))
        let store: ActiveSetStore = UserDefaultsActiveSetStore(defaults: suite)
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

    func testSwappingBackendKeepsObservableAPIIdentical() {
        // The same operations against local vs sync-capable backends are observationally identical.
        let local = KeyValueActiveSetStore(store: UserDefaultsKeyValueStore(
            defaults: UserDefaults(suiteName: "test.swap.\(UUID().uuidString)")!))
        let sync = KeyValueActiveSetStore(store: InMemoryKeyValueStore())
        for store in [local, sync] as [ActiveSetStore] {
            store.save(["p", "q"], for: .mountain)
            XCTAssertEqual(store.load(for: .mountain), ["p", "q"])
        }
    }
}
