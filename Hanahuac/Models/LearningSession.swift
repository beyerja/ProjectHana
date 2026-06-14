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

    private let category: CardCategory?
    private let store: ActiveSetStore?

    var current: ReviewCard? {
        activeSet.indices.contains(currentIndex) ? activeSet[currentIndex] : nil
    }

    /// Convenience init (no persistence) — used by tests and non-category paths.
    convenience init(newCards: [ReviewCard]) {
        self.init(newCards: newCards, category: nil, store: nil)
    }

    /// Designated init with optional active-set persistence.
    init(newCards: [ReviewCard], category: CardCategory?, store: ActiveSetStore?) {
        totalNewCards = newCards.count
        self.category = category
        self.store = store

        // Build a lookup from factID → ReviewCard for rehydration.
        let byID = Dictionary(uniqueKeysWithValues: newCards.map { ($0.factID, $0) })

        if let category, let store {
            let storedIDs = store.load(for: category)
            let rehydrated = storedIDs.compactMap { byID[$0] }.filter { !$0.hasGraduated }

            if !rehydrated.isEmpty {
                // Resume the previously persisted active set.
                activeSet = rehydrated
                let activeIDs = Set(rehydrated.map(\.factID))
                let remaining = newCards.filter { !activeIDs.contains($0.factID) && !$0.hasGraduated }
                pendingPool = remaining.shuffled()
            } else {
                // Stored IDs all graduated (or store was empty); draw a fresh set.
                store.clear(for: category)
                let shuffled = newCards.shuffled()
                activeSet = Array(shuffled.prefix(LearningSession.activeSetSize))
                pendingPool = Array(shuffled.dropFirst(LearningSession.activeSetSize))
                store.save(activeSet.map(\.factID), for: category)
            }
        } else {
            // No persistence.
            let shuffled = newCards.shuffled()
            activeSet = Array(shuffled.prefix(LearningSession.activeSetSize))
            pendingPool = Array(shuffled.dropFirst(LearningSession.activeSetSize))
        }
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

        // Persist updated active-set membership.
        if let category, let store {
            if activeSet.isEmpty {
                store.clear(for: category)
            } else {
                store.save(activeSet.map(\.factID), for: category)
            }
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
