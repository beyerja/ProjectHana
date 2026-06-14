import Foundation
import MapKit
import Observation

/// A learning session for new country cards that uses the map quiz interaction
/// and the same 3-consecutive-correct graduation mechanic as `LearningSession`.
///
/// - `recordCorrect()` / `recordWrong()` drive the streak; 3 in a row graduates a card.
/// - The existing `MapQuizSession` (used for due/Pending cards) is unchanged.
/// - Pass a `category` and `store` to persist the active set across app restarts,
///   matching the behaviour of `LearningSession` for non-country categories.
@Observable
final class MapLearningSession {
    static let activeSetSize = 10
    static let requiredStreak = 3

    // MARK: - Learning state

    private(set) var activeSet: [ReviewCard]
    private(set) var pendingPool: [ReviewCard]
    private(set) var currentIndex = 0
    private(set) var graduatedCount = 0
    private(set) var isFinished = false
    let totalNewCards: Int

    // MARK: - Map state

    let allCountries: [Country]
    private(set) var answerState: AnswerState = .unanswered
    private(set) var annotationCountries: [Country] = []
    private(set) var mapRegion: MKCoordinateRegion = MKCoordinateRegion()

    private let category: CardCategory?
    private let store: ActiveSetStore?

    var current: ReviewCard? {
        activeSet.indices.contains(currentIndex) ? activeSet[currentIndex] : nil
    }

    var currentCountry: Country? {
        guard let card = current else { return nil }
        return allCountries.first { $0.id == card.factID }
    }

    // MARK: - Init

    /// Convenience init (no persistence) — used by tests and paths with no category.
    convenience init(newCards: [ReviewCard], allCountries: [Country]) {
        self.init(newCards: newCards, allCountries: allCountries, category: nil, store: nil)
    }

    /// Designated init with optional active-set persistence.
    init(newCards: [ReviewCard], allCountries: [Country], category: CardCategory?, store: ActiveSetStore?) {
        totalNewCards = newCards.count
        self.allCountries = allCountries
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
                activeSet = Array(shuffled.prefix(MapLearningSession.activeSetSize))
                pendingPool = Array(shuffled.dropFirst(MapLearningSession.activeSetSize))
                store.save(activeSet.map(\.factID), for: category)
            }
        } else {
            // No persistence.
            let shuffled = newCards.shuffled()
            activeSet = Array(shuffled.prefix(MapLearningSession.activeSetSize))
            pendingPool = Array(shuffled.dropFirst(MapLearningSession.activeSetSize))
        }

        refreshAnnotations()
    }

    // MARK: - Map interaction

    func handleTap(countryID: String) {
        guard answerState == .unanswered, currentCountry != nil else { return }
        guard let correct = currentCountry else { return }
        if countryID == correct.id {
            answerState = .correct(id: countryID)
        } else {
            answerState = .incorrect(tappedID: countryID, correctID: correct.id)
        }
    }

    // MARK: - Answer recording (called after the UI delay)

    func recordCorrect() {
        guard let card = current else { return }
        card.consecutiveCorrect += 1
        if card.consecutiveCorrect >= MapLearningSession.requiredStreak {
            graduate(card)
        } else {
            advance()
        }
        answerState = .unanswered
        if !isFinished { refreshAnnotations() }
    }

    func recordWrong() {
        guard let card = current else { return }
        card.consecutiveCorrect = 0

        // Dual-penalty: also reset the streak of the incorrectly-tapped country's card if present.
        if case .incorrect(let tappedID, _) = answerState, tappedID != card.factID {
            if let tappedCard = activeSet.first(where: { $0.factID == tappedID }) {
                tappedCard.consecutiveCorrect = 0
            }
        }

        // Reinsert later in the queue (same as LearningSession)
        activeSet.remove(at: currentIndex)
        let insertAt = Int.random(in: max(1, currentIndex)..<max(2, activeSet.count + 1))
        activeSet.insert(card, at: min(insertAt, activeSet.count))
        if currentIndex >= activeSet.count { currentIndex = 0 }
        answerState = .unanswered
        refreshAnnotations()
    }

    // MARK: - Private

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

    private func refreshAnnotations() {
        guard let correct = currentCountry else { return }
        let result = makeQuizAnnotations(correct: correct, allCountries: allCountries)
        annotationCountries = result.countries
        mapRegion = result.region
    }
}
