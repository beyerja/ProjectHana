import Foundation

// MARK: - PreferenceStore

/// Persists user-facing app preferences that should sync (currently the selected `AppLocale`).
/// Backed by a `KeyValueStore`, so it works over local `UserDefaults` (sync off / fallback) or
/// `NSUbiquitousKeyValueStore` (sync on) without the caller knowing which.
protocol PreferenceStore: AnyObject {
    func string(forKey key: PreferenceKey) -> String?
    func setString(_ value: String, forKey key: PreferenceKey)
}

/// Stable keys for synced preferences. Raw values match the historical `UserDefaults` keys so
/// existing local selections are read transparently.
enum PreferenceKey: String {
    case appLocale
}

// MARK: - KeyValueStore-backed implementation

final class KeyValuePreferenceStore: PreferenceStore {
    private let store: KeyValueStore

    init(store: KeyValueStore) {
        self.store = store
    }

    func string(forKey key: PreferenceKey) -> String? {
        store.string(forKey: key.rawValue)
    }

    func setString(_ value: String, forKey key: PreferenceKey) {
        store.setString(value, forKey: key.rawValue)
        store.synchronize()
    }
}

// MARK: - Factories

/// The local/disabled-sync default: backed by `UserDefaults.standard`. Preserves today's behavior.
func makeLocalPreferenceStore() -> PreferenceStore {
    KeyValuePreferenceStore(store: UserDefaultsKeyValueStore())
}

/// The sync-capable variant: backed by `NSUbiquitousKeyValueStore`. Selected by `SyncCoordinator`
/// only when sync is enabled and available.
func makeUbiquitousPreferenceStore() -> PreferenceStore {
    KeyValuePreferenceStore(store: UbiquitousKeyValueStore())
}
