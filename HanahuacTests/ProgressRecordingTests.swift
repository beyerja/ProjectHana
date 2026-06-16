import SwiftData
import XCTest
@testable import Hanahuac

/// Exercises the story-002 recording hook: completing a quiz review should drive
/// `ProgressStatsStore.recordSnapshot` so exactly one snapshot exists for today, reflecting the
/// post-review card state. Mirrors how the quiz views call the store after `session.advance()`.
@MainActor
final class ProgressRecordingTests: XCTestCase {
    private var container: ModelContainer!
    private var cardStore: CardStore!
    private var statsStore: ProgressStatsStore!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        cardStore = CardStore(modelContext: container.mainContext)
        statsStore = ProgressStatsStore(modelContext: container.mainContext)
    }

    override func tearDownWithError() throws {
        cardStore.resetAll()
        container = nil
        cardStore = nil
        statsStore = nil
    }

    /// Simulate what a quiz view does on review completion: advance the session, then record.
    private func recordAfterReview() {
        statsStore.recordSnapshot(cards: cardStore.allCards, streak: StreakTracker.currentStreak())
    }

    func testSingleReviewRecordsOneSnapshotForToday() throws {
        let card = ReviewCard(factID: "fr-paris", category: .country)
        cardStore.upsert(card)

        // A multiple-choice session over the one card; answer it, then advance.
        let question = MCQQuestion(
            card: card,
            prompt: "?",
            options: [
                MCQOption(label: "A", isCorrect: true),
                MCQOption(label: "B", isCorrect: false)
            ]
        )
        let session = MultipleChoiceSession(questions: [question])
        let current = try XCTUnwrap(session.current)
        let correctID = try XCTUnwrap(current.options.first(where: \.isCorrect)).id
        session.select(optionID: correctID)
        session.advance()

        recordAfterReview()

        let today = Calendar.current.startOfDay(for: .now)
        let todaySnapshots = statsStore.allSnapshots.filter {
            Calendar.current.isDate($0.day, inSameDayAs: today)
        }
        XCTAssertEqual(todaySnapshots.count, 1, "Exactly one snapshot for today")
        let snap = try XCTUnwrap(todaySnapshots.first)
        XCTAssertEqual(snap.reviewsCompleted, 1, "The reviewed card has repetitionCount > 0")
    }

    func testRepeatedReviewsStayOnOneSnapshot() {
        let cards = (0 ..< 3).map { ReviewCard(factID: "f\($0)", category: .country) }
        for c in cards {
            cardStore.upsert(c)
        }

        // Record after each of several reviews on the same day.
        for _ in 0 ..< 3 {
            recordAfterReview()
        }

        let today = Calendar.current.startOfDay(for: .now)
        let todaySnapshots = statsStore.allSnapshots.filter {
            Calendar.current.isDate($0.day, inSameDayAs: today)
        }
        XCTAssertEqual(todaySnapshots.count, 1, "Repeated same-day recordings keep one snapshot")
    }
}
