import Foundation

// MARK: - Protocol

/// Persists the ordered list of factIDs that form the learning active set for a given category.
protocol ActiveSetStore {
    func load(for category: CardCategory) -> [String]
    func save(_ factIDs: [String], for category: CardCategory)
    func clear(for category: CardCategory)
}

/// The per-language persistence key for a category's active set: `activeSet.<language>.<category>`.
/// The active set is tracked independently per language, so the key carries the `AppLocale.rawValue`.
func activeSetKey(language: String, category: CardCategory) -> String {
    "activeSet.\(language).\(category.rawValue)"
}

/// The legacy, pre-per-language key (`activeSet.<category>`). Exposed for the one-time upgrade
/// migration that copies legacy active sets into the active language's namespaced key.
func legacyActiveSetKey(for category: CardCategory) -> String {
    "activeSet.\(category.rawValue)"
}

// MARK: - UserDefaults implementation

final class UserDefaultsActiveSetStore: ActiveSetStore {
    private let defaults: UserDefaults
    /// The `AppLocale.rawValue` whose active set this store reads/writes. The active set is
    /// per-language, so the persistence key is namespaced by language.
    private let language: String

    init(language: String, defaults: UserDefaults = .standard) {
        self.language = language
        self.defaults = defaults
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, category: category)
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
    private let language: String

    init(store: KeyValueStore, language: String) {
        self.store = store
        self.language = language
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, category: category)
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

/// Convenience factory for the sync-capable active-set store (`NSUbiquitousKeyValueStore`-backed)
/// for a given language. Selected by `SyncCoordinator` only when sync is enabled and available.
func makeUbiquitousActiveSetStore(language: String) -> ActiveSetStore {
    KeyValueActiveSetStore(store: UbiquitousKeyValueStore(), language: language)
}

// MARK: - In-memory implementation (for tests)

/// In-memory active-set store. Namespaces storage by (`language`, `category`) so per-language
/// isolation can be exercised without `UserDefaults`.
final class InMemoryActiveSetStore: ActiveSetStore {
    private let language: String
    private var storage: [String: [String]] = [:]

    init(language: String) {
        self.language = language
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, category: category)
    }

    func load(for category: CardCategory) -> [String] {
        storage[key(for: category)] ?? []
    }

    func save(_ factIDs: [String], for category: CardCategory) {
        storage[key(for: category)] = factIDs
    }

    func clear(for category: CardCategory) {
        storage.removeValue(forKey: key(for: category))
    }
}
