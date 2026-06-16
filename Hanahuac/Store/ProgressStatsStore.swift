import Foundation
import Observation
import SwiftData

/// Persists and reads the daily progress rollup (`DailyProgressSnapshot`).
///
/// Mirrors `CardStore`'s shape: it owns a `ModelContext`, exposes a fetch accessor, and enforces
/// per-day uniqueness in app logic via an upsert (CloudKit forbids `@Attribute(.unique)`, so two
/// devices can independently write a snapshot for the same day; `recordSnapshot` and `deduplicate`
/// converge those to one).
@Observable
final class ProgressStatsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// All snapshots, oldest day first.
    var allSnapshots: [DailyProgressSnapshot] {
        var descriptor = FetchDescriptor<DailyProgressSnapshot>()
        descriptor.sortBy = [SortDescriptor(\.day)]
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Snapshots on or after `start` (inclusive), oldest day first. Pass `nil` for all-time.
    func snapshots(since start: Date?) -> [DailyProgressSnapshot] {
        guard let start else { return allSnapshots }
        let boundary = Calendar.current.startOfDay(for: start)
        return allSnapshots.filter { $0.day >= boundary }
    }

    /// Computes today's rollup from the current cards + streak and upserts the single snapshot for
    /// `startOfDay(date)`. Idempotent within a day: repeated calls keep exactly one snapshot for the
    /// day and refresh its fields to the latest values.
    func recordSnapshot(
        cards: [ReviewCard],
        streak: Int,
        date: Date = .now
    ) {
        let day = Calendar.current.startOfDay(for: date)

        // Collapse any pre-existing duplicates for this day (e.g. from a CloudKit merge) first.
        let snapshot = canonicalSnapshot(for: day) ?? {
            let new = DailyProgressSnapshot(day: day)
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
    }

    /// Collapses snapshots that share a `day` down to a single canonical snapshot, keeping the one
    /// with the most reviews (then most graduated, then most mastered, as deterministic tie-breaks).
    /// Returns the number of snapshots removed.
    @discardableResult
    func deduplicate() -> Int {
        let grouped = Dictionary(grouping: allSnapshots) { Calendar.current.startOfDay(for: $0.day) }
        var removed = 0
        for (_, snaps) in grouped where snaps.count > 1 {
            let sorted = snaps.sorted(by: Self.isRicher)
            for loser in sorted.dropFirst() {
                modelContext.delete(loser)
                removed += 1
            }
        }
        if removed > 0 { try? modelContext.save() }
        return removed
    }

    // MARK: - Private

    /// Returns the canonical (richest) snapshot for `day`, after collapsing any same-day duplicates.
    private func canonicalSnapshot(for day: Date) -> DailyProgressSnapshot? {
        let matches = allSnapshots.filter { Calendar.current.isDate($0.day, inSameDayAs: day) }
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
