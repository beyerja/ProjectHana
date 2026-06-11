import Foundation
import Observation

@Observable
final class LearningSession {
    static let activeSetSize = 10
    static let requiredStreak = 3

    private(set) var activeSet: [ReviewCard]
    private(set) var pendingPool: [ReviewCard]
    private(set) var currentIndex = 0
    private(set) var graduatedCount = 0
    private(set) var isFinished = false

    let totalNewCards: Int

    var current: ReviewCard? {
        activeSet.indices.contains(currentIndex) ? activeSet[currentIndex] : nil
    }

    init(newCards: [ReviewCard]) {
        totalNewCards = newCards.count
        let shuffled = newCards.shuffled()
        activeSet = Array(shuffled.prefix(LearningSession.activeSetSize))
        pendingPool = Array(shuffled.dropFirst(LearningSession.activeSetSize))
    }

    func recordCorrect() {
        guard let card = current else { return }
        card.consecutiveCorrect += 1
        if card.consecutiveCorrect >= LearningSession.requiredStreak {
            graduate(card)
        } else {
            advance()
        }
    }

    func recordWrong() {
        guard let card = current else { return }
        card.consecutiveCorrect = 0
        // Remove from current position and reinsert at a later random position
        activeSet.remove(at: currentIndex)
        let insertAt = Int.random(in: max(1, currentIndex)..<max(2, activeSet.count + 1))
        activeSet.insert(card, at: min(insertAt, activeSet.count))
        // currentIndex stays, now pointing to the next card (or wraps)
        if currentIndex >= activeSet.count { currentIndex = 0 }
    }

    // MARK: – Private

    private func graduate(_ card: ReviewCard) {
        card.hasGraduated = true
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        SM2Scheduler.apply(result, to: card, quality: 4)
        graduatedCount += 1

        activeSet.remove(at: currentIndex)

        if let next = pendingPool.first {
            pendingPool.removeFirst()
            activeSet.append(next)
        }

        if activeSet.isEmpty {
            isFinished = true
        } else if currentIndex >= activeSet.count {
            currentIndex = 0
        }
    }

    private func advance() {
        currentIndex = (currentIndex + 1) % max(1, activeSet.count)
    }
}
