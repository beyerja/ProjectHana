import Foundation

// MARK: - KeyValueStore façade

/// A minimal key-value abstraction shared by the local (`UserDefaults`) and sync-capable
/// (`NSUbiquitousKeyValueStore`) backends.
///
/// This seam exists so the ubiquitous-backed stores can be unit-tested with an in-memory fake
/// and so the rest of the app never depends on a concrete backend. It deliberately covers only
/// the value shapes the app persists today (string arrays and strings).
///
/// Referencing `NSUbiquitousKeyValueStore` in code does NOT require an iCloud entitlement; it
/// only *syncs at runtime* when the iCloud Key-Value entitlement is present. With sync disabled
/// (the default), the ubiquitous backend is simply never selected — see `SyncCoordinator`.
protocol KeyValueStore: AnyObject {
    func stringArray(forKey key: String) -> [String]?
    func setStringArray(_ value: [String], forKey key: String)
    func string(forKey key: String) -> String?
    func setString(_ value: String, forKey key: String)
    func removeObject(forKey key: String)
    /// Best-effort flush to the underlying store. No-op for backends that persist immediately.
    func synchronize()
}

// MARK: - UserDefaults backend (local / disabled-sync fallback)

final class UserDefaultsKeyValueStore: KeyValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func stringArray(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    func setStringArray(_ value: [String], forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func setString(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    func synchronize() { /* UserDefaults persists automatically. */ }
}

// MARK: - NSUbiquitousKeyValueStore backend (sync-capable)

/// Backed by `NSUbiquitousKeyValueStore`. Only actually syncs across devices when the iCloud
/// Key-Value Store entitlement is present (see `docs/icloud-sync.md`); otherwise it behaves like
/// a local store. Selected only when sync is enabled AND available.
final class UbiquitousKeyValueStore: KeyValueStore {
    private let store: NSUbiquitousKeyValueStore

    init(store: NSUbiquitousKeyValueStore = .default) {
        self.store = store
    }

    func stringArray(forKey key: String) -> [String]? {
        store.array(forKey: key) as? [String]
    }

    func setStringArray(_ value: [String], forKey key: String) {
        store.set(value, forKey: key)
    }

    func string(forKey key: String) -> String? {
        store.string(forKey: key)
    }

    func setString(_ value: String, forKey key: String) {
        store.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        store.removeObject(forKey: key)
    }

    func synchronize() {
        store.synchronize()
    }
}

// MARK: - In-memory backend (tests)

/// Entitlement-free fake used to exercise both the ubiquitous-backed and local-backed stores in
/// unit tests without touching `UserDefaults` or a live iCloud key-value store.
final class InMemoryKeyValueStore: KeyValueStore {
    private(set) var storage: [String: Any] = [:]

    func stringArray(forKey key: String) -> [String]? {
        storage[key] as? [String]
    }

    func setStringArray(_ value: [String], forKey key: String) {
        storage[key] = value
    }

    func string(forKey key: String) -> String? {
        storage[key] as? String
    }

    func setString(_ value: String, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func synchronize() { /* no-op */ }
}
