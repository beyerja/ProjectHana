import Foundation
import Observation
import SwiftData

/// Persists and reads the spaced-repetition card state (`ReviewCard`) for a *single active language
/// AND quiz mode*.
///
/// Progress is tracked independently per language and per quiz mode: a `CardStore` is constructed with
/// the active `language` (an `AppLocale.rawValue`) and `quizMode` (a `QuizModeID.rawValue`), and every
/// read/write is scoped to BOTH. Two languages — or two modes within a language — may hold a
/// `ReviewCard` for the same `factID` without colliding: the canonical identity of a card is
/// (`factID`, `language`, `quizMode`). Seeding one (language, mode) never touches another, and
/// `resetAll` only clears the active (language, mode). The app vends one `CardStore` per active mode
/// through `CardStoreProvider` and rebuilds them when `LanguageManager.current` changes.
@Observable
final class CardStore {
    private let modelContext: ModelContext

    /// The `AppLocale.rawValue` whose cards this store reads and writes.
    let language: String

    /// The `QuizModeID.rawValue` whose cards this store reads and writes. Empty string is the
    /// legacy/aggregate sentinel (only used by stores built before per-mode scoping, e.g. some tests);
    /// production stores always carry a concrete mode.
    let quizMode: String

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

    init(modelContext: ModelContext, language: String, quizMode: String = "") {
        self.modelContext = modelContext
        self.language = language
        self.quizMode = quizMode
        ensureGraduationConsistency()
    }

    /// All cards for the active (language, quizMode).
    var allCards: [ReviewCard] {
        let lang = language
        let mode = quizMode
        let descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.language == lang && $0.quizMode == mode }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func dueCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let now = Date.now
        let lang = language
        let mode = quizMode
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate {
                $0.language == lang && $0.quizMode == mode && $0.nextReviewDate <= now && $0.hasGraduated
            }
        )
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        let cards = (try? modelContext.fetch(descriptor)) ?? []
        guard let category else { return cards }
        return cards.filter { $0.cardCategory == category }
    }

    func newCards(for category: CardCategory? = nil) -> [ReviewCard] {
        let lang = language
        let mode = quizMode
        var descriptor = FetchDescriptor<ReviewCard>(
            predicate: #Predicate { $0.language == lang && $0.quizMode == mode && !$0.hasGraduated }
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

    /// Persists in-place mutations made to live `ReviewCard` instances on the shared `ModelContext`
    /// (e.g. the SR fields a quiz session updates while grading) and bumps the revision signal.
    ///
    /// This is the routing point every quiz view calls after each graded answer. The sessions mutate
    /// their `ReviewCard` `@Model` instances directly and would otherwise rely on SwiftData autosave,
    /// which never bumps `revision` — leaving the home count pills and Progress screen stale until a
    /// relaunch. Calling this saves the context and bumps the signal, so the pills update immediately
    /// even on a grading path that skips `recordSnapshot`. SR field computation is unchanged; this only
    /// flushes and signals the already-applied mutation.
    func persistCardChanges() {
        try? modelContext.save()
        markChanged()
    }

    /// Inserts/updates a card in the active (language, quizMode). The card is stamped with this store's
    /// `language`/`quizMode` if it does not already carry one, so cards inserted through the active
    /// store always belong to that (language, mode) track (real seeded cards are already stamped; this
    /// also keeps callers that build a bare `ReviewCard` consistent with the store they insert it into).
    func upsert(_ card: ReviewCard) {
        if card.language.isEmpty { card.language = language }
        if card.quizMode.isEmpty { card.quizMode = quizMode }
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
    /// (language, quizMode)*, inserting only the factIDs that are missing for that (language, mode).
    ///
    /// This is duplicate-safe by design. CloudKit forbids `@Attribute(.unique)`, so two devices
    /// that each call this on a fresh-but-soon-to-sync store can independently create cards for
    /// the same (factID, language, quizMode). By (a) deduplicating first and (b) inserting only missing
    /// factIDs (rather than the old "insert everything iff the store is empty"), seeding converges
    /// to one card per fact per (language, mode) even when partial state already exists. Newly-inserted
    /// cards are stamped with this store's `language`/`quizMode`, so seeding one (language, mode) never
    /// creates cards for another — and a fact absent in a (language, mode) simply gets no card there
    /// (the data model makes no assumption that every language/mode shares the identical fact set).
    ///
    /// `categories` restricts which categories are seeded — a mode that does not serve a category
    /// (e.g. `typeCapital`, Countries-only) passes only the categories it quizzes, so it never holds
    /// cards for a category it cannot present. Defaults to all categories.
    func seedIfNeeded(with data: GeographyData, categories: [CardCategory] = CardCategory.allCases) {
        // Collapse any pre-existing duplicates for this (language, mode) (e.g. from a prior CloudKit
        // merge) first, so the "already present" set below is accurate.
        deduplicate()

        var existingFactIDs = Set(allCards.map(\.factID))
        let allowed = Set(categories)

        func seed(_ ids: [String], as category: CardCategory) {
            guard allowed.contains(category) else { return }
            for id in ids where !existingFactIDs.contains(id) {
                modelContext.insert(ReviewCard(factID: id, language: language, quizMode: quizMode, category: category))
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

    /// Collapses `ReviewCard`s that share a `factID` *within the active (language, quizMode)* down to a
    /// single canonical card. The same `factID` in a different language OR a different quiz mode is NOT
    /// a duplicate (`allCards` is already scoped to this store's language and mode).
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
        // `allCards` is already (language, quizMode)-scoped, so grouping by factID alone keys on
        // (factID, language, quizMode) for this store's language and mode.
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
