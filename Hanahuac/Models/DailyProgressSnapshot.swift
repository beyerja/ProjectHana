import Foundation
import SwiftData

/// A compact, once-per-day rollup of the user's learning progress, persisted so the app can chart
/// trends over time. One snapshot represents one calendar day (`day` is normalized to
/// `Calendar.startOfDay`).
///
/// CloudKit compatibility: like `ReviewCard`, this `@Model` is designed so the *same* schema can
/// later back a CloudKit-mirrored SwiftData container with no further model changes (see
/// `docs/icloud-sync.md`). CloudKit requires every stored attribute to be optional or carry a
/// default value, and it forbids `@Attribute(.unique)`. Therefore:
/// - every stored property below has an explicit model-level default value, and
/// - there is intentionally NO `@Attribute(.unique)` on `day` (or anything else).
///   Uniqueness-per-day is enforced in app logic instead (see `ProgressStatsStore.recordSnapshot`
///   and `ProgressStatsStore.deduplicate()`), because two devices can independently write a snapshot
///   for the same day and CloudKit will not reject the duplicate at the store layer.
///
/// Per-category breakdown is stored as parallel defaulted `Int` columns (not an array or relationship)
/// so the schema stays primitive and CloudKit-safe. `reviewCount`/`masteredCount` are the totals;
/// the `*Review`/`*Mastered` columns are the per-`CardCategory` slices that the UI category filter
/// reads.
@Model
final class DailyProgressSnapshot {
    /// Calendar-day boundary (`startOfDay`) this snapshot summarizes.
    var day: Date = Calendar.current.startOfDay(for: .now)

    /// The `AppLocale.rawValue` this snapshot's stats belong to. Stats are tracked independently per
    /// language, so the canonical identity of a snapshot is (`day`, `language`, `quizMode`). An empty
    /// string is the legacy/unassigned sentinel for rows created before per-language progress existed;
    /// the one-time upgrade migration stamps those with the active locale. Defaulted (never
    /// `@Attribute(.unique)`) to stay CloudKit-sync-ready.
    var language: String = ""

    /// The `QuizModeID.rawValue` this snapshot's stats belong to, OR an empty string for the
    /// **mode-aggregated** rollup (the totals the Progress screen shows by default). Daily stats are
    /// recorded both per mode and as an aggregate, so the canonical identity of a snapshot is
    /// (`day`, `language`, `quizMode`); the empty-`quizMode` row is the aggregate, and a non-empty
    /// `quizMode` row is that mode's slice (backing the per-mode breakdown). Defaulted (never
    /// `@Attribute(.unique)`) to stay CloudKit-sync-ready.
    var quizMode: String = ""

    /// Number of reviews completed across all quiz modes on this day (cumulative, last-write-wins
    /// within the day via upsert).
    var reviewsCompleted: Int = 0

    /// Number of cards that have graduated (`hasGraduated == true`) as of this snapshot.
    var cardsGraduated: Int = 0

    /// The day-streak value (`StreakTracker.currentStreak()`) as of this snapshot.
    var streak: Int = 0

    // MARK: - Mastery totals (across all categories)

    /// Total cards classified at the `.review` tier as of this snapshot.
    var reviewCount: Int = 0
    /// Total cards classified at the `.mastered` tier as of this snapshot.
    var masteredCount: Int = 0

    // MARK: - Per-category Review-tier counts

    var countryReview: Int = 0
    var riverReview: Int = 0
    var mountainReview: Int = 0
    var seaReview: Int = 0

    // MARK: - Per-category Mastered-tier counts

    var countryMastered: Int = 0
    var riverMastered: Int = 0
    var mountainMastered: Int = 0
    var seaMastered: Int = 0

    init(
        day: Date = Calendar.current.startOfDay(for: .now),
        language: String = "",
        quizMode: String = "",
        reviewsCompleted: Int = 0,
        cardsGraduated: Int = 0,
        streak: Int = 0,
        reviewCount: Int = 0,
        masteredCount: Int = 0,
        countryReview: Int = 0,
        riverReview: Int = 0,
        mountainReview: Int = 0,
        seaReview: Int = 0,
        countryMastered: Int = 0,
        riverMastered: Int = 0,
        mountainMastered: Int = 0,
        seaMastered: Int = 0
    ) {
        self.day = day
        self.language = language
        self.quizMode = quizMode
        self.reviewsCompleted = reviewsCompleted
        self.cardsGraduated = cardsGraduated
        self.streak = streak
        self.reviewCount = reviewCount
        self.masteredCount = masteredCount
        self.countryReview = countryReview
        self.riverReview = riverReview
        self.mountainReview = mountainReview
        self.seaReview = seaReview
        self.countryMastered = countryMastered
        self.riverMastered = riverMastered
        self.mountainMastered = mountainMastered
        self.seaMastered = seaMastered
    }

    /// Review-tier count for a specific category (or the total when `category` is nil).
    func reviewCount(for category: CardCategory?) -> Int {
        guard let category else { return reviewCount }
        switch category {
        case .country: return countryReview
        case .river: return riverReview
        case .mountain: return mountainReview
        case .sea: return seaReview
        }
    }

    /// Mastered-tier count for a specific category (or the total when `category` is nil).
    func masteredCount(for category: CardCategory?) -> Int {
        guard let category else { return masteredCount }
        switch category {
        case .country: return countryMastered
        case .river: return riverMastered
        case .mountain: return mountainMastered
        case .sea: return seaMastered
        }
    }
}
