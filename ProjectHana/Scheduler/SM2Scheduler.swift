import Foundation

struct SM2Result {
    let newRepetitionCount: Int
    let newEaseFactor: Double
    let newIntervalDays: Int
    let nextReviewDate: Date
}

struct SM2Scheduler {
    static func schedule(card: ReviewCard, quality: Int) -> SM2Result {
        precondition((0...5).contains(quality), "quality must be 0–5")

        let q = Double(quality)

        // Ease factor update (applied regardless of pass/fail)
        let newEF = max(1.3, card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))

        let newRepetition: Int
        let newInterval: Int

        if quality < 3 {
            // Failed recall — restart
            newRepetition = 0
            newInterval = 1
        } else {
            newRepetition = card.repetitionCount + 1
            switch card.repetitionCount {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = max(1, Int((Double(card.intervalDays) * newEF).rounded()))
            }
        }

        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: newInterval,
            to: Date.now
        ) ?? Date.now

        return SM2Result(
            newRepetitionCount: newRepetition,
            newEaseFactor: newEF,
            newIntervalDays: newInterval,
            nextReviewDate: nextDate
        )
    }

    static func apply(_ result: SM2Result, to card: ReviewCard, quality: Int) {
        card.repetitionCount = result.newRepetitionCount
        card.easeFactor = result.newEaseFactor
        card.intervalDays = result.newIntervalDays
        card.nextReviewDate = result.nextReviewDate
        card.lastQualityScore = quality
    }
}
