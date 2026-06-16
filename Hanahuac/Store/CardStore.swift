import Foundation
import Observation
import SwiftData

@Observable
final class CardStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        ensureGraduationConsistency()
    }

    var allCards: [ReviewCard] {
        (try? modelContext.fetch(FetchDescriptor<ReviewCard>())) ?? []
    }

    func dueCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let now = Date.now
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.nextReviewDate <= now && $0.hasGraduated }
        )
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    func newCards(for category: CardCategory? = nil) -> [ReviewCard] {
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { !$0.hasGraduated }
        )
        descriptor.sortBy = [SortDescriptor(\.factID)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    private func ensureGraduationConsistency() {
        let cards = allCards
        var changed = false
        for card in cards where !card.hasGraduated && (card.repetitionCount > 0 || card.intervalDays > 1) {
            card.hasGraduated = true
            changed = true
        }
        if changed { try? modelContext.save() }
    }

    func upsert(_ card: ReviewCard) {
        modelContext.insert(card)
        try? modelContext.save()
    }

    func resetAll() {
        let cards = allCards
        for card in cards {
            modelContext.delete(card)
        }
        try? modelContext.save()
    }

    /// Seeds the store so there is exactly one `ReviewCard` per catalog fact, inserting only the
    /// factIDs that are missing.
    ///
    /// This is duplicate-safe by design. CloudKit forbids `@Attribute(.unique)`, so two devices
    /// that each call this on a fresh-but-soon-to-sync store can independently create cards for
    /// the same factID. By (a) deduplicating first and (b) inserting only missing factIDs (rather
    /// than the old "insert everything iff the store is empty"), seeding converges to one card per
    /// fact even when partial state already exists. For the default single-device, no-sync case the
    /// observable result is unchanged: an empty store gets exactly one card per fact.
    func seedIfNeeded(with data: GeographyData) {
        // Collapse any pre-existing duplicates (e.g. arriving from a prior CloudKit merge) first,
        // so the "already present" set below is accurate.
        deduplicate()

        var existingFactIDs = Set(allCards.map(\.factID))

        func seed(_ ids: [String], as category: CardCategory) {
            for id in ids where !existingFactIDs.contains(id) {
                modelContext.insert(ReviewCard(factID: id, category: category))
                existingFactIDs.insert(id)
            }
        }

        seed(data.countries.map(\.id), as: .country)
        seed(data.rivers.map(\.id), as: .river)
        seed(data.mountains.map(\.id), as: .mountain)
        seed(data.seas.map(\.id), as: .sea)

        try? modelContext.save()
    }

    /// Collapses `ReviewCard`s that share a `factID` down to a single canonical card.
    ///
    /// CloudKit's last-writer-wins + lack of unique constraints means independent devices can both
    /// create a card for the same fact. When those rows converge in one store we must reduce them to
    /// one. Winner selection is deterministic and favors the most-progressed card so learning
    /// progress is never lost to a fresher-but-emptier duplicate:
    ///   1. graduated cards beat non-graduated,
    ///   2. then higher `repetitionCount`,
    ///   3. then higher `consecutiveCorrect`,
    ///   4. then later `nextReviewDate`,
    ///   5. finally lowest `id` (UUID string) as a stable tie-breaker.
    /// Losing duplicates are deleted. Returns the number of cards removed.
    @discardableResult
    func deduplicate() -> Int {
        let grouped = Dictionary(grouping: allCards, by: \.factID)
        var removed = 0
        for (_, cards) in grouped where cards.count > 1 {
            let sorted = cards.sorted(by: Self.isMoreProgressed)
            // Keep the first (most-progressed); delete the rest.
            for loser in sorted.dropFirst() {
                modelContext.delete(loser)
                removed += 1
            }
        }
        if removed > 0 { try? modelContext.save() }
        return removed
    }

    /// Ordering predicate: returns true when `lhs` should win over `rhs` as the canonical card.
    private static func isMoreProgressed(_ lhs: ReviewCard, _ rhs: ReviewCard) -> Bool {
        if lhs.hasGraduated != rhs.hasGraduated { return lhs.hasGraduated }
        if lhs.repetitionCount != rhs.repetitionCount { return lhs.repetitionCount > rhs.repetitionCount }
        if lhs.consecutiveCorrect != rhs.consecutiveCorrect { return lhs.consecutiveCorrect > rhs.consecutiveCorrect }
        if lhs.nextReviewDate != rhs.nextReviewDate { return lhs.nextReviewDate > rhs.nextReviewDate }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
