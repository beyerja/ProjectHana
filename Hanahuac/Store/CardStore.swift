import Foundation
import Observation
import SwiftData

/// Persists and reads the spaced-repetition card state (`ReviewCard`) for a *single active language*.
///
/// Progress is tracked independently per language: a `CardStore` is constructed with the active
/// `language` (an `AppLocale.rawValue`) and every read/write is scoped to it. Two languages may hold
/// a `ReviewCard` for the same `factID` without colliding — the canonical identity of a card is
/// (`factID`, `language`). Seeding language A never touches language B, and `resetAll` only clears
/// the active language. To present a different language's track, build a new `CardStore` with that
/// language (the app rebuilds it when `LanguageManager.current` changes).
@Observable
final class CardStore {
    private let modelContext: ModelContext

    /// The `AppLocale.rawValue` whose cards this store reads and writes.
    let language: String

    /// Monotonic mutation counter bumped after every persisted change. The fetch accessors
    /// (`allCards`/`newCards`/`dueCards`) run a fresh `FetchDescriptor` and read no `@Observable`
    /// stored property, so SwiftUI Observation registers no dependency on them. A view that reads
    /// `revision` in its `body` (even discarding the value) ties its invalidation to this counter and
    /// therefore recomputes its fetch-derived numbers after each mutation.
    private(set) var revision: Int = 0

    /// Bumps `revision` after a persisted mutation. `&+=` (wrapping add) keeps a long-lived store from
    /// trapping on overflow.
    private func markChanged() {
        revision &+= 1
    }

    init(modelContext: ModelContext, language: String) {
        self.modelContext = modelContext
        self.language = language
        ensureGraduationConsistency()
    }

    /// All cards for the active language.
    var allCards: [ReviewCard] {
        let lang = language
        let descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.language == lang }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func dueCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let now = Date.now
        let lang = language
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.language == lang && $0.nextReviewDate <= now && $0.hasGraduated }
        )
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    func newCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let lang = language
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.language == lang && !$0.hasGraduated }
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
        if changed {
            try? modelContext.save()
            markChanged()
        }
    }

    /// Inserts/updates a card in the active language. The card is stamped with this store's
    /// `language` if it does not already carry one, so cards inserted through the active store always
    /// belong to that language's track (real seeded cards are already stamped; this also keeps
    /// callers that build a bare `ReviewCard` consistent with the store they insert it into).
    func upsert(_ card: ReviewCard) {
        if card.language.isEmpty { card.language = language }
        modelContext.insert(card)
        try? modelContext.save()
        markChanged()
    }

    /// Clears every card for the *active language only*; other languages' tracks are untouched.
    func resetAll() {
        let cards = allCards
        for card in cards {
            modelContext.delete(card)
        }
        try? modelContext.save()
        markChanged()
    }

    /// Seeds the store so there is exactly one `ReviewCard` per catalog fact *for the active
    /// language*, inserting only the factIDs that are missing for that language.
    ///
    /// This is duplicate-safe by design. CloudKit forbids `@Attribute(.unique)`, so two devices
    /// that each call this on a fresh-but-soon-to-sync store can independently create cards for
    /// the same (factID, language). By (a) deduplicating first and (b) inserting only missing
    /// factIDs (rather than the old "insert everything iff the store is empty"), seeding converges
    /// to one card per fact per language even when partial state already exists. Newly-inserted
    /// cards are stamped with this store's `language`, so seeding one language never creates cards
    /// for another — and a fact absent in a language simply gets no card there (the data model makes
    /// no assumption that every language shares the identical fact set).
    func seedIfNeeded(with data: GeographyData) {
        // Collapse any pre-existing duplicates for this language (e.g. from a prior CloudKit merge)
        // first, so the "already present" set below is accurate.
        deduplicate()

        var existingFactIDs = Set(allCards.map(\.factID))

        func seed(_ ids: [String], as category: CardCategory) {
            for id in ids where !existingFactIDs.contains(id) {
                modelContext.insert(ReviewCard(factID: id, language: language, category: category))
                existingFactIDs.insert(id)
            }
        }

        seed(data.countries.map(\.id), as: .country)
        seed(data.rivers.map(\.id), as: .river)
        seed(data.mountains.map(\.id), as: .mountain)
        seed(data.seas.map(\.id), as: .sea)

        try? modelContext.save()
        markChanged()
    }

    /// Collapses `ReviewCard`s that share a `factID` *within the active language* down to a single
    /// canonical card. The same `factID` in a different language is NOT a duplicate.
    ///
    /// CloudKit's last-writer-wins + lack of unique constraints means independent devices can both
    /// create a card for the same (fact, language). When those rows converge in one store we must
    /// reduce them to one. Winner selection is deterministic and favors the most-progressed card so
    /// learning progress is never lost to a fresher-but-emptier duplicate:
    ///   1. graduated cards beat non-graduated,
    ///   2. then higher `repetitionCount`,
    ///   3. then higher `consecutiveCorrect`,
    ///   4. then later `nextReviewDate`,
    ///   5. finally lowest `id` (UUID string) as a stable tie-breaker.
    /// Losing duplicates are deleted. Returns the number of cards removed.
    @discardableResult
    func deduplicate() -> Int {
        // `allCards` is already language-scoped, so grouping by factID alone keys on (factID,
        // language) for this store's language.
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
        if removed > 0 {
            try? modelContext.save()
            markChanged()
        }
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
