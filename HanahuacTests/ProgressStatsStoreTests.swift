import SwiftData
import XCTest
@testable import Hanahuac

@MainActor
final class ProgressStatsStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: ProgressStatsStore!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = ProgressStatsStore(modelContext: container.mainContext, language: Self.lang)
    }

    private static let lang = AppLocale.en.rawValue

    override func tearDownWithError() throws {
        container = nil
        store = nil
    }

    // MARK: - Helpers

    private func card(_ category: CardCategory, reps: Int, ease: Double = 2.5, graduated: Bool = false) -> ReviewCard {
        ReviewCard(
            factID: UUID().uuidString,
            category: category,
            repetitionCount: reps,
            easeFactor: ease,
            hasGraduated: graduated
        )
    }

    private func day(offset: Int) throws -> Date {
        let cal = Calendar.current
        return try XCTUnwrap(cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: .now)))
    }

    // MARK: - Insert

    func testFirstSnapshotInserts() {
        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 1)
        XCTAssertEqual(store.allSnapshots.count, 1)
        XCTAssertEqual(store.allSnapshots.first?.reviewCount, 1)
    }

    func testSnapshotCapturesMetrics() throws {
        let cards = [
            card(.country, reps: 0), // new
            card(.country, reps: 1), // learning
            card(.country, reps: 3, graduated: true), // review
            card(.river, reps: 5, ease: 2.5, graduated: true) // mastered
        ]
        store.recordSnapshot(cards: cards, streak: 4)
        let snap = try XCTUnwrap(store.allSnapshots.first)
        XCTAssertEqual(snap.reviewsCompleted, 3) // reps > 0
        XCTAssertEqual(snap.cardsGraduated, 2)
        XCTAssertEqual(snap.streak, 4)
        XCTAssertEqual(snap.reviewCount, 1)
        XCTAssertEqual(snap.masteredCount, 1)
    }

    // MARK: - Idempotent upsert within a day

    func testSameDayUpsertKeepsOneSnapshotAndUpdatesFields() throws {
        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 1)
        store.recordSnapshot(cards: [card(.country, reps: 3), card(.country, reps: 4)], streak: 2)
        XCTAssertEqual(store.allSnapshots.count, 1, "Same day should not add a second snapshot")
        let snap = try XCTUnwrap(store.allSnapshots.first)
        XCTAssertEqual(snap.reviewCount, 2, "Fields should reflect the latest call")
        XCTAssertEqual(snap.streak, 2)
    }

    // MARK: - Multi-day accumulation + range query

    func testMultiDayAccumulationAndRangeOrdering() throws {
        let tenDaysAgo = try day(offset: -10)
        let threeDaysAgo = try day(offset: -3)
        let today = try day(offset: 0)
        let sixDaysAgo = try day(offset: -6)
        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 1, date: tenDaysAgo)
        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 2, date: threeDaysAgo)
        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 3, date: today)

        XCTAssertEqual(store.allSnapshots.count, 3)
        // Ordered oldest-first.
        let days = store.allSnapshots.map(\.day)
        XCTAssertEqual(days, days.sorted())

        // 7-day window excludes the -10 snapshot.
        let recent = store.snapshots(since: sixDaysAgo)
        XCTAssertEqual(recent.count, 2)
    }

    func testSnapshotsSinceNilReturnsAll() throws {
        let fiveDaysAgo = try day(offset: -5)
        let today = try day(offset: 0)
        store.recordSnapshot(cards: [card(.country, reps: 1)], streak: 1, date: fiveDaysAgo)
        store.recordSnapshot(cards: [card(.country, reps: 1)], streak: 1, date: today)
        XCTAssertEqual(store.snapshots(since: nil).count, 2)
    }

    // MARK: - Per-category aggregation

    func testPerCategoryBreakdown() throws {
        let cards = [
            card(.country, reps: 3, graduated: true), // country review
            card(.river, reps: 5, ease: 2.5, graduated: true), // river mastered
            card(.mountain, reps: 3, graduated: true), // mountain review
            card(.sea, reps: 5, ease: 2.5, graduated: true) // sea mastered
        ]
        store.recordSnapshot(cards: cards, streak: 1)
        let snap = try XCTUnwrap(store.allSnapshots.first)
        XCTAssertEqual(snap.reviewCount(for: .country), 1)
        XCTAssertEqual(snap.masteredCount(for: .river), 1)
        XCTAssertEqual(snap.reviewCount(for: .mountain), 1)
        XCTAssertEqual(snap.masteredCount(for: .sea), 1)
        XCTAssertEqual(snap.reviewCount(for: nil), 2) // total review
        XCTAssertEqual(snap.masteredCount(for: nil), 2) // total mastered
        XCTAssertEqual(snap.reviewCount(for: .river), 0)
    }

    // MARK: - Deduplicate

    func testDeduplicateCollapsesSameDayDuplicates() throws {
        let d = try day(offset: -1)
        // Insert two raw snapshots for the same day directly.
        let a = DailyProgressSnapshot(day: d, language: Self.lang, reviewsCompleted: 5)
        let b = DailyProgressSnapshot(day: d, language: Self.lang, reviewsCompleted: 2)
        container.mainContext.insert(a)
        container.mainContext.insert(b)
        try container.mainContext.save()
        XCTAssertEqual(store.allSnapshots.count, 2)

        let removed = store.deduplicate()
        XCTAssertEqual(removed, 1)
        XCTAssertEqual(store.allSnapshots.count, 1)
        // The richer one (more reviews) survives.
        XCTAssertEqual(store.allSnapshots.first?.reviewsCompleted, 5)
    }

    func testRecordSnapshotCollapsesPreexistingDuplicates() throws {
        let today = Calendar.current.startOfDay(for: .now)
        container.mainContext.insert(DailyProgressSnapshot(day: today, language: Self.lang, reviewsCompleted: 1))
        container.mainContext.insert(DailyProgressSnapshot(day: today, language: Self.lang, reviewsCompleted: 1))
        try container.mainContext.save()
        XCTAssertEqual(store.allSnapshots.count, 2)

        store.recordSnapshot(cards: [card(.country, reps: 3)], streak: 1)
        XCTAssertEqual(store.allSnapshots.count, 1, "recordSnapshot should collapse same-day duplicates")
    }
}
