import Foundation
import SwiftData

enum CardCategory: String, Codable, Hashable {
    case country
    case river
    case mountain
    case sea
}

/// CloudKit compatibility: this `@Model` is designed so the *same* schema can later back a
/// CloudKit-mirrored SwiftData container with no further model changes (see `docs/icloud-sync.md`).
/// CloudKit requires every stored attribute to be optional or carry a default value, and it
/// forbids `@Attribute(.unique)`. Therefore:
/// - every stored property below has an explicit model-level default value, and
/// - there is intentionally NO `@Attribute(.unique)` on `factID` (or anything else).
///   Uniqueness-per-fact is enforced in app logic instead (see `CardStore.deduplicate(...)`
///   and `CardStore.seedIfNeeded(...)`), because two devices can independently seed the same
///   catalog and CloudKit will not reject the duplicate at the store layer.
@Model
final class ReviewCard {
    var id: UUID = UUID()
    var factID: String = ""
    /// The `AppLocale.rawValue` this card's progress belongs to. Progress is tracked independently
    /// per language AND per quiz mode, so the canonical identity of a card is
    /// (`factID`, `language`, `quizMode`). An empty string is the legacy/unassigned sentinel for rows
    /// created before per-language progress existed; the one-time upgrade migration stamps those with
    /// the active locale (see the migration story). Defaulted (never `@Attribute(.unique)`) to stay
    /// CloudKit-sync-ready.
    var language: String = ""
    /// The `QuizModeID.rawValue` this card's progress belongs to. Each quiz mode keeps an independent
    /// spaced-repetition track for a fact, so a fact may hold up to one card per mode within a
    /// language. An empty string is the legacy/unassigned sentinel for rows created before
    /// per-quiz-mode progress existed; the one-time upgrade migration stamps those with `mapQuiz` (all
    /// legacy progress was effectively the Map Tab Quiz). Defaulted (never `@Attribute(.unique)`) to
    /// stay CloudKit-sync-ready.
    var quizMode: String = ""
    var category: String = CardCategory.country.rawValue // CardCategory rawValue — SwiftData needs primitive types
    var repetitionCount: Int = 0
    var easeFactor: Double = 2.5
    var intervalDays: Int = 0
    var nextReviewDate: Date = Date.now
    var lastQualityScore: Int?
    var consecutiveCorrect: Int = 0 // learning-phase streak; resets to 0 on wrong answer
    var hasGraduated: Bool = false // true once the card enters the SM-2 schedule

    init(
        id: UUID = UUID(),
        factID: String,
        language: String = "",
        quizMode: String = "",
        category: CardCategory,
        repetitionCount: Int = 0,
        easeFactor: Double = 2.5,
        intervalDays: Int = 0,
        nextReviewDate: Date = .now,
        lastQualityScore: Int? = nil,
        consecutiveCorrect: Int = 0,
        hasGraduated: Bool = false
    ) {
        self.id = id
        self.factID = factID
        self.language = language
        self.quizMode = quizMode
        self.category = category.rawValue
        self.repetitionCount = repetitionCount
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastQualityScore = lastQualityScore
        self.consecutiveCorrect = consecutiveCorrect
        self.hasGraduated = hasGraduated
    }

    var cardCategory: CardCategory {
        CardCategory(rawValue: category) ?? .country
    }
}
