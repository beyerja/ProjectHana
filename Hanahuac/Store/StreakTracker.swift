import Foundation

/// Tracks the day-streak **per language**. Progress is independent per language, so each language
/// keeps its own streak count and last-review date under language-namespaced `UserDefaults` keys
/// (`streak_count.<language>` / `streak_lastReviewDate.<language>`). A streak in one language is
/// unaffected by activity in another. `language` is an `AppLocale.rawValue`.
///
/// The legacy un-namespaced keys (`streak_count` / `streak_lastReviewDate`) are migrated to the
/// active language's keys by the one-time upgrade migration; this type only reads/writes the
/// per-language keys.
enum StreakTracker {
    private static let lastReviewKeyPrefix = "streak_lastReviewDate"
    private static let streakKeyPrefix = "streak_count"

    /// The legacy, pre-per-language keys (no language suffix). Exposed for the upgrade migration.
    static let legacyLastReviewKey = lastReviewKeyPrefix
    static let legacyStreakKey = streakKeyPrefix

    static func lastReviewKey(for language: String) -> String {
        "\(lastReviewKeyPrefix).\(language)"
    }

    static func streakKey(for language: String) -> String {
        "\(streakKeyPrefix).\(language)"
    }

    static func currentStreak(language: String, defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: streakKey(for: language))
    }

    /// Call this after any quiz session completes at least one review in `language`.
    static func recordReview(language: String, on date: Date = .now, defaults: UserDefaults = .standard) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let streakKey = streakKey(for: language)
        let lastReviewKey = lastReviewKey(for: language)

        if let raw = defaults.object(forKey: lastReviewKey) as? Date {
            let lastDay = cal.startOfDay(for: raw)
            if cal.isDate(lastDay, inSameDayAs: today) {
                // Already recorded today — no change needed.
                return
            }
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            if cal.isDate(lastDay, inSameDayAs: yesterday) {
                // Consecutive day — extend streak.
                defaults.set(defaults.integer(forKey: streakKey) + 1, forKey: streakKey)
            } else {
                // Gap — reset to 1.
                defaults.set(1, forKey: streakKey)
            }
        } else {
            // First ever review in this language.
            defaults.set(1, forKey: streakKey)
        }

        defaults.set(today, forKey: lastReviewKey)
    }
}
