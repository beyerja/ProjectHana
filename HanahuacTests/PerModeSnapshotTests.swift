import SwiftData
import XCTest
@testable import Hanahuac

/// Story 003 — daily snapshots are recorded both per quiz mode and as a mode-aggregated rollup.
/// The aggregated `quizMode == ""` row (the Progress screen's default) must reflect ALL modes, and a
/// per-`(day, language, quizMode)` row must exist for the breakdown — without one mode overwriting
/// another or the aggregate.
@MainActor
final class PerModeSnapshotTests: XCTestCase {
    private var container: ModelContainer!
    private var statsStore: ProgressStatsStore!
    private let lang = AppLocale.en.rawValue

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        statsStore = ProgressStatsStore(modelContext: container.mainContext, language: lang)
    }

    override func tearDownWithError() throws {
        container = nil
        statsStore = nil
    }

    /// A reviewed card (repetitionCount > 0 counts as a completed review) for a mode.
    private func reviewed(_ factID: String, mode: QuizModeID) -> ReviewCard {
        ReviewCard(factID: factID, language: lang, quizMode: mode.rawValue, category: .country, repetitionCount: 3)
    }

    func testAggregateReflectsAllModesNotJustTheLastGraded() throws {
        let mapCards = [reviewed("a", mode: .mapQuiz)]
        let mcCards = [reviewed("b", mode: .multipleChoice)]
        let allCards = mapCards + mcCards

        // Grade in mapQuiz, then multipleChoice — each call passes the full cross-mode union as the
        // aggregate, mirroring the quiz views.
        statsStore.recordSnapshot(allCards: allCards, modeCards: mapCards, mode: .mapQuiz, streak: 1)
        statsStore.recordSnapshot(allCards: allCards, modeCards: mcCards, mode: .multipleChoice, streak: 1)

        let aggregate = try XCTUnwrap(statsStore.allSnapshots.last)
        XCTAssertEqual(aggregate.quizMode, "", "allSnapshots returns the aggregate rows")
        XCTAssertEqual(
            aggregate.reviewsCompleted, 2,
            "Aggregate counts reviews across BOTH modes, not just the last one graded"
        )
    }

    func testPerModeSnapshotsAreIndependent() throws {
        let mapCards = [reviewed("a", mode: .mapQuiz), reviewed("c", mode: .mapQuiz)]
        let mcCards = [reviewed("b", mode: .multipleChoice)]
        let allCards = mapCards + mcCards

        statsStore.recordSnapshot(allCards: allCards, modeCards: mapCards, mode: .mapQuiz, streak: 1)
        statsStore.recordSnapshot(allCards: allCards, modeCards: mcCards, mode: .multipleChoice, streak: 1)

        let map = try XCTUnwrap(statsStore.snapshots(forQuizMode: QuizModeID.mapQuiz.rawValue).last)
        let mc = try XCTUnwrap(statsStore.snapshots(forQuizMode: QuizModeID.multipleChoice.rawValue).last)
        XCTAssertEqual(map.reviewsCompleted, 2, "mapQuiz slice reflects only its 2 cards")
        XCTAssertEqual(mc.reviewsCompleted, 1, "multipleChoice slice reflects only its 1 card")
    }

    func testAggregateAndPerModeRowsCoexistForSameDay() {
        let mapCards = [reviewed("a", mode: .mapQuiz)]
        statsStore.recordSnapshot(allCards: mapCards, modeCards: mapCards, mode: .mapQuiz, streak: 1)

        // One aggregate (`""`) row + one mapQuiz row for today; same day, different mode → not dupes.
        XCTAssertEqual(statsStore.allSnapshots.count, 1)
        XCTAssertEqual(statsStore.snapshots(forQuizMode: QuizModeID.mapQuiz.rawValue).count, 1)
        XCTAssertEqual(statsStore.deduplicate(), 0, "Aggregate vs per-mode rows are not duplicates")
    }

    func testRepeatedRecordingIsIdempotentPerDayAndMode() {
        let mapCards = [reviewed("a", mode: .mapQuiz)]
        statsStore.recordSnapshot(allCards: mapCards, modeCards: mapCards, mode: .mapQuiz, streak: 1)
        statsStore.recordSnapshot(allCards: mapCards, modeCards: mapCards, mode: .mapQuiz, streak: 1)
        XCTAssertEqual(statsStore.allSnapshots.count, 1, "One aggregate row per day")
        XCTAssertEqual(
            statsStore.snapshots(forQuizMode: QuizModeID.mapQuiz.rawValue).count, 1,
            "One per-mode row per (day, mode)"
        )
    }

    func testStreakIsSharedAcrossModes() throws {
        // A review in ANY mode advances the single per-language streak (StreakTracker is per-language,
        // not per-mode). Use an isolated UserDefaults suite to avoid cross-test bleed.
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "PerModeSnapshotTests.streak"))
        defaults.removePersistentDomain(forName: "PerModeSnapshotTests.streak")

        StreakTracker.recordReview(language: lang, on: .now, defaults: defaults)
        XCTAssertEqual(StreakTracker.currentStreak(language: lang, defaults: defaults), 1)
        // A second review the same day (different mode) does not double-count, but keeps the streak.
        StreakTracker.recordReview(language: lang, on: .now, defaults: defaults)
        XCTAssertEqual(
            StreakTracker.currentStreak(language: lang, defaults: defaults), 1,
            "Streak is shared per-language across modes — same-day reviews keep it at 1"
        )
        defaults.removePersistentDomain(forName: "PerModeSnapshotTests.streak")
    }
}
