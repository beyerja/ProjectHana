import Foundation

struct StreakTracker {
    private static let lastReviewKey = "streak_lastReviewDate"
    private static let streakKey = "streak_count"

    static func currentStreak(defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: streakKey)
    }

    // Call this after any quiz session completes at least one review.
    static func recordReview(on date: Date = .now, defaults: UserDefaults = .standard) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)

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
            // First ever review.
            defaults.set(1, forKey: streakKey)
        }

        defaults.set(today, forKey: lastReviewKey)
    }
}
