import Foundation

// MARK: - Protocol

/// Persists the ordered list of factIDs that form the learning active set for a given category.
protocol ActiveSetStore {
    func load(for category: CardCategory) -> [String]
    func save(_ factIDs: [String], for category: CardCategory)
    func clear(for category: CardCategory)
}

/// The persistence key for a category's active set.
///
/// The active set is tracked independently per language AND per quiz mode, so the key carries the
/// `AppLocale.rawValue` and the `QuizModeID.rawValue`:
/// - `mode != nil` → `activeSet.<language>.<mode>.<category>` (the per-mode key production uses).
/// - `mode == nil` → `activeSet.<language>.<category>` — the pre-per-mode **per-language** key. This
///   is the migration SOURCE the one-time upgrade copies into each mode's `mapQuiz` key, and the
///   default for back-compat callers/tests.
func activeSetKey(language: String, mode: QuizModeID? = nil, category: CardCategory) -> String {
    if let mode {
        return "activeSet.\(language).\(mode.rawValue).\(category.rawValue)"
    }
    return "activeSet.\(language).\(category.rawValue)"
}

/// The pre-per-mode, per-language key (`activeSet.<language>.<category>`). Exposed for the one-time
/// per-quiz-mode migration that copies the legacy per-language active set into the `mapQuiz` per-mode
/// key.
func legacyPerLanguageActiveSetKey(language: String, category: CardCategory) -> String {
    activeSetKey(language: language, mode: nil, category: category)
}

/// The legacy, pre-per-language key (`activeSet.<category>`). Exposed for the one-time per-language
/// upgrade migration that copies legacy active sets into the active language's namespaced key.
func legacyActiveSetKey(for category: CardCategory) -> String {
    "activeSet.\(category.rawValue)"
}

// MARK: - UserDefaults implementation

final class UserDefaultsActiveSetStore: ActiveSetStore {
    private let defaults: UserDefaults
    /// The `AppLocale.rawValue` whose active set this store reads/writes. The active set is
    /// per-language AND per-quiz-mode, so the persistence key is namespaced by both.
    private let language: String
    /// The `QuizModeID` whose active set this store reads/writes. `nil` selects the pre-per-mode
    /// per-language key (back-compat / migration source).
    private let mode: QuizModeID?

    init(language: String, mode: QuizModeID? = nil, defaults: UserDefaults = .standard) {
        self.language = language
        self.mode = mode
        self.defaults = defaults
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, mode: mode, category: category)
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
    private let mode: QuizModeID?

    init(store: KeyValueStore, language: String, mode: QuizModeID? = nil) {
        self.store = store
        self.language = language
        self.mode = mode
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, mode: mode, category: category)
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
func makeUbiquitousActiveSetStore(language: String, mode: QuizModeID? = nil) -> ActiveSetStore {
    KeyValueActiveSetStore(store: UbiquitousKeyValueStore(), language: language, mode: mode)
}

// MARK: - In-memory implementation (for tests)

/// In-memory active-set store. Namespaces storage by (`language`, `mode`, `category`) so per-language
/// and per-mode isolation can be exercised without `UserDefaults`.
final class InMemoryActiveSetStore: ActiveSetStore {
    private let language: String
    private let mode: QuizModeID?
    private var storage: [String: [String]] = [:]

    init(language: String, mode: QuizModeID? = nil) {
        self.language = language
        self.mode = mode
    }

    private func key(for category: CardCategory) -> String {
        activeSetKey(language: language, mode: mode, category: category)
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
