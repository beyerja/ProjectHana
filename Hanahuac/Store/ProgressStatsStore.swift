import Foundation
import Observation
import SwiftData

/// Persists and reads the daily progress rollup (`DailyProgressSnapshot`) for a *single active
/// language*.
///
/// Mirrors `CardStore`'s shape: it owns a `ModelContext`, is constructed with the active `language`
/// (an `AppLocale.rawValue`), exposes language-scoped fetch accessors, and enforces per-day
/// uniqueness *within that language* in app logic via an upsert (CloudKit forbids
/// `@Attribute(.unique)`, so two devices can independently write a snapshot for the same
/// (day, language); `recordSnapshot` and `deduplicate` converge those to one). Each language keeps
/// its own day-by-day history; the same `day` across two languages is not a duplicate.
@Observable
final class ProgressStatsStore {
    private let modelContext: ModelContext

    /// The `AppLocale.rawValue` whose snapshots this store reads and writes.
    let language: String

    /// Monotonic mutation counter bumped after every persisted change. The fetch accessor
    /// (`allSnapshots`) runs a fresh `FetchDescriptor` and reads no `@Observable` stored property, so
    /// SwiftUI Observation registers no dependency on it. A view that reads `revision` in its `body`
    /// (even discarding the value) ties its invalidation to this counter and therefore recomputes its
    /// fetch-derived numbers after each mutation.
    private(set) var revision: Int = 0

    /// Bumps `revision` after a persisted mutation. `&+=` (wrapping add) keeps a long-lived store from
    /// trapping on overflow.
    private func markChanged() {
        revision &+= 1
    }

    init(modelContext: ModelContext, language: String) {
        self.modelContext = modelContext
        self.language = language
    }

    /// All **aggregate** snapshots for the active language (the mode-aggregated `quizMode == ""` rows),
    /// oldest day first. This is the default the Progress screen charts; per-mode rows are excluded so
    /// the default view is unchanged by per-mode recording.
    var allSnapshots: [DailyProgressSnapshot] {
        snapshots(forQuizMode: "")
    }

    /// All snapshots for the active language and a specific `quizMode` (use `""` for the aggregate),
    /// oldest day first.
    func snapshots(forQuizMode quizMode: String) -> [DailyProgressSnapshot] {
        let lang = language
        let mode = quizMode
        var descriptor = FetchDescriptor<DailyProgressSnapshot>(
            predicate: #Predicate { $0.language == lang && $0.quizMode == mode }
        )
        descriptor.sortBy = [SortDescriptor(\.day)]
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Aggregate snapshots on or after `start` (inclusive), oldest day first. Pass `nil` for all-time.
    func snapshots(since start: Date?) -> [DailyProgressSnapshot] {
        snapshots(forQuizMode: "", since: start)
    }

    /// Per-`quizMode` snapshots on or after `start` (inclusive), oldest day first — backs the per-mode
    /// breakdown. Pass `quizMode: ""` for the aggregate, `nil` start for all-time.
    func snapshots(forQuizMode quizMode: String, since start: Date?) -> [DailyProgressSnapshot] {
        let all = snapshots(forQuizMode: quizMode)
        guard let start else { return all }
        let boundary = Calendar.current.startOfDay(for: start)
        return all.filter { $0.day >= boundary }
    }

    /// Records the **mode-aggregated** rollup (the `quizMode == ""` snapshot the Progress screen shows
    /// by default) for `date` from `cards`. Idempotent within a day. This is the back-compatible entry
    /// point; callers that want both the aggregate AND a per-mode slice use
    /// ``recordSnapshot(allCards:modeCards:mode:streak:date:)``.
    func recordSnapshot(
        cards: [ReviewCard],
        streak: Int,
        date: Date = .now
    ) {
        recordSnapshot(cards: cards, streak: streak, quizMode: "", date: date)
    }

    /// Records both the mode-aggregated rollup (from `allCards`, the cross-mode union) AND the per-mode
    /// rollup for `mode` (from `modeCards`) for `date`. Use this from the quiz views so the aggregate
    /// snapshot reflects every mode (not just the one just graded) while per-mode data is captured for
    /// the breakdown.
    func recordSnapshot(
        allCards: [ReviewCard],
        modeCards: [ReviewCard],
        mode: QuizModeID,
        streak: Int,
        date: Date = .now
    ) {
        recordSnapshot(cards: allCards, streak: streak, quizMode: "", date: date)
        recordSnapshot(cards: modeCards, streak: streak, quizMode: mode.rawValue, date: date)
    }

    /// Computes the rollup from `cards` + `streak` and upserts the single snapshot for
    /// `(startOfDay(date), language, quizMode)`. Idempotent within a (day, mode): repeated calls keep
    /// exactly one snapshot and refresh its fields to the latest values.
    private func recordSnapshot(
        cards: [ReviewCard],
        streak: Int,
        quizMode: String,
        date: Date = .now
    ) {
        let day = Calendar.current.startOfDay(for: date)

        // Collapse any pre-existing duplicates for this (day, language, quizMode) first.
        let snapshot = canonicalSnapshot(for: day, quizMode: quizMode) ?? {
            let new = DailyProgressSnapshot(day: day, language: language, quizMode: quizMode)
            modelContext.insert(new)
            return new
        }()

        var reviewsCompleted = 0
        var cardsGraduated = 0
        var reviewTotal = 0
        var masteredTotal = 0
        var perCategoryReview: [CardCategory: Int] = [:]
        var perCategoryMastered: [CardCategory: Int] = [:]

        for card in cards {
            if card.repetitionCount > 0 { reviewsCompleted += 1 }
            if card.hasGraduated { cardsGraduated += 1 }
            switch MasteryTier.classify(card) {
            case .review:
                reviewTotal += 1
                perCategoryReview[card.cardCategory, default: 0] += 1
            case .mastered:
                masteredTotal += 1
                perCategoryMastered[card.cardCategory, default: 0] += 1
            case .new, .learning:
                break
            }
        }

        snapshot.reviewsCompleted = reviewsCompleted
        snapshot.cardsGraduated = cardsGraduated
        snapshot.streak = streak
        snapshot.reviewCount = reviewTotal
        snapshot.masteredCount = masteredTotal
        snapshot.countryReview = perCategoryReview[.country, default: 0]
        snapshot.riverReview = perCategoryReview[.river, default: 0]
        snapshot.mountainReview = perCategoryReview[.mountain, default: 0]
        snapshot.seaReview = perCategoryReview[.sea, default: 0]
        snapshot.countryMastered = perCategoryMastered[.country, default: 0]
        snapshot.riverMastered = perCategoryMastered[.river, default: 0]
        snapshot.mountainMastered = perCategoryMastered[.mountain, default: 0]
        snapshot.seaMastered = perCategoryMastered[.sea, default: 0]

        try? modelContext.save()
        markChanged()
    }

    /// Collapses snapshots that share a `(day, quizMode)` *within the active language* down to a single
    /// canonical snapshot, keeping the one with the most reviews (then most graduated, then most
    /// mastered, as deterministic tie-breaks). The same `day` in another language, OR in another
    /// `quizMode` (including the aggregate `""` row vs. a per-mode row), is NOT a duplicate. Returns
    /// the number of snapshots removed.
    @discardableResult
    func deduplicate() -> Int {
        let allModeSnapshots = allLanguageSnapshots
        let grouped = Dictionary(grouping: allModeSnapshots) { snap in
            DayMode(day: Calendar.current.startOfDay(for: snap.day), quizMode: snap.quizMode)
        }
        var removed = 0
        for (_, snaps) in grouped where snaps.count > 1 {
            let sorted = snaps.sorted(by: Self.isRicher)
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

    // MARK: - Private

    /// A `(day, quizMode)` grouping key for dedup — the canonical identity of a snapshot within a
    /// language.
    private struct DayMode: Hashable {
        let day: Date
        let quizMode: String
    }

    /// Every snapshot for the active language across ALL quiz modes (aggregate + per-mode rows).
    private var allLanguageSnapshots: [DailyProgressSnapshot] {
        let lang = language
        let descriptor = FetchDescriptor<DailyProgressSnapshot>(
            predicate: #Predicate { $0.language == lang }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Returns the canonical (richest) snapshot for `(day, quizMode)`, after collapsing any duplicates
    /// for that exact (day, mode). Snapshots for other modes on the same day are left untouched.
    private func canonicalSnapshot(for day: Date, quizMode: String) -> DailyProgressSnapshot? {
        let matches = snapshots(forQuizMode: quizMode)
            .filter { Calendar.current.isDate($0.day, inSameDayAs: day) }
        guard let winner = matches.min(by: Self.isRicher) else { return nil }
        for loser in matches where loser !== winner {
            modelContext.delete(loser)
        }
        return winner
    }

    /// Ordering predicate: true when `lhs` should win over `rhs` as the canonical snapshot.
    private static func isRicher(_ lhs: DailyProgressSnapshot, _ rhs: DailyProgressSnapshot) -> Bool {
        if lhs.reviewsCompleted != rhs.reviewsCompleted { return lhs.reviewsCompleted > rhs.reviewsCompleted }
        if lhs.cardsGraduated != rhs.cardsGraduated { return lhs.cardsGraduated > rhs.cardsGraduated }
        return lhs.masteredCount > rhs.masteredCount
    }
}
