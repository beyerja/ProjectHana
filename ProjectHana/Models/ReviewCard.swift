import Foundation
import SwiftData

enum CardCategory: String, Codable, Hashable {
    case country
    case river
    case mountain
    case sea
}

@Model
final class ReviewCard {
    var id: UUID
    var factID: String
    var category: String          // CardCategory rawValue — SwiftData needs primitive types
    var repetitionCount: Int
    var easeFactor: Double
    var intervalDays: Int
    var nextReviewDate: Date
    var lastQualityScore: Int?
    var consecutiveCorrect: Int   // learning-phase streak; resets to 0 on wrong answer
    var hasGraduated: Bool        // true once the card enters the SM-2 schedule

    init(
        id: UUID = UUID(),
        factID: String,
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
