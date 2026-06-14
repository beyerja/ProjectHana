import XCTest
import SwiftData
@testable import Hanahuac

@MainActor
final class StatsTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(repetitions: Int, easeFactor: Double = 2.5) -> ReviewCard {
        let card = ReviewCard(factID: UUID().uuidString, category: .country,
                              repetitionCount: repetitions, easeFactor: easeFactor)
        container.mainContext.insert(card)
        return card
    }

    // MARK: – Mastery tier classification

    func testTier_zeroReps_isNew() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 0)), .new)
    }

    func testTier_oneRep_isLearning() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 1)), .learning)
    }

    func testTier_twoReps_isLearning() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 2)), .learning)
    }

    func testTier_threeReps_isReview() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 3)), .review)
    }

    func testTier_fourReps_isReview() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 4)), .review)
    }

    func testTier_fiveRepsHighEF_isMastered() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 5, easeFactor: 2.5)), .mastered)
    }

    func testTier_fiveRepsExactEFBoundary_isMastered() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 5, easeFactor: 2.0)), .mastered)
    }

    func testTier_fiveRepsLowEF_isReview() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 5, easeFactor: 1.3)), .review)
    }

    func testTier_tenRepsLowEF_isReview() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 10, easeFactor: 1.9)), .review)
    }

    func testTier_tenRepsHighEF_isMastered() {
        XCTAssertEqual(MasteryTier.classify(makeCard(repetitions: 10, easeFactor: 2.1)), .mastered)
    }

    // MARK: – Streak logic

    private func freshDefaults() -> UserDefaults {
        let name = "test_\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testStreak_firstReview_isOne() {
        let d = freshDefaults()
        StreakTracker.recordReview(on: .now, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(defaults: d), 1)
    }

    func testStreak_reviewTwiceSameDay_remainsOne() {
        let d = freshDefaults()
        let today = Date.now
        StreakTracker.recordReview(on: today, defaults: d)
        StreakTracker.recordReview(on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(defaults: d), 1)
    }

    func testStreak_consecutiveDays_increments() {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        StreakTracker.recordReview(on: yesterday, defaults: d)
        StreakTracker.recordReview(on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(defaults: d), 2)
    }

    func testStreak_threeDaysInARow() {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let d1 = cal.date(byAdding: .day, value: -2, to: today)!
        let d2 = cal.date(byAdding: .day, value: -1, to: today)!
        StreakTracker.recordReview(on: d1, defaults: d)
        StreakTracker.recordReview(on: d2, defaults: d)
        StreakTracker.recordReview(on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(defaults: d), 3)
    }

    func testStreak_missedDay_resetsToOne() {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!
        StreakTracker.recordReview(on: twoDaysAgo, defaults: d)
        StreakTracker.recordReview(on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(defaults: d), 1)
    }
}
