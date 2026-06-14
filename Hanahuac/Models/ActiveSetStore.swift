import Foundation

// MARK: - Protocol

/// Persists the ordered list of factIDs that form the learning active set for a given category.
protocol ActiveSetStore {
    func load(for category: CardCategory) -> [String]
    func save(_ factIDs: [String], for category: CardCategory)
    func clear(for category: CardCategory)
}

// MARK: - UserDefaults implementation

final class UserDefaultsActiveSetStore: ActiveSetStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(for category: CardCategory) -> String {
        "activeSet.\(category.rawValue)"
    }

    func load(for category: CardCategory) -> [String] {
        defaults.stringArray(forKey: key(for: category)) ?? []
    }

    func save(_ factIDs: [String], for category: CardCategory) {
        defaults.set(factIDs, forKey: key(for: category))
    }

    func clear(for category: CardCategory) {
        defaults.removeObject(forKey: key(for: category))
    }
}

// MARK: - KeyValueStore-backed implementation

/// Persists the active set through a `KeyValueStore` façade, so the *same* implementation works
/// over local `UserDefaults` (sync off / fallback) or `NSUbiquitousKeyValueStore` (sync on).
/// The key scheme matches `UserDefaultsActiveSetStore` exactly so existing local data is read
/// transparently.
final class KeyValueActiveSetStore: ActiveSetStore {
    private let store: KeyValueStore

    init(store: KeyValueStore) {
        self.store = store
    }

    private func key(for category: CardCategory) -> String {
        "activeSet.\(category.rawValue)"
    }

    func load(for category: CardCategory) -> [String] {
        store.stringArray(forKey: key(for: category)) ?? []
    }

    func save(_ factIDs: [String], for category: CardCategory) {
        store.setStringArray(factIDs, forKey: key(for: category))
        store.synchronize()
    }

    func clear(for category: CardCategory) {
        store.removeObject(forKey: key(for: category))
        store.synchronize()
    }
}

/// Convenience factory for the sync-capable active-set store (`NSUbiquitousKeyValueStore`-backed).
/// Selected by `SyncCoordinator` only when sync is enabled and available.
func makeUbiquitousActiveSetStore() -> ActiveSetStore {
    KeyValueActiveSetStore(store: UbiquitousKeyValueStore())
}

// MARK: - In-memory implementation (for tests)

final class InMemoryActiveSetStore: ActiveSetStore {
    private var storage: [String: [String]] = [:]

    func load(for category: CardCategory) -> [String] {
        storage[category.rawValue] ?? []
    }

    func save(_ factIDs: [String], for category: CardCategory) {
        storage[category.rawValue] = factIDs
    }

    func clear(for category: CardCategory) {
        storage.removeValue(forKey: category.rawValue)
    }
}
