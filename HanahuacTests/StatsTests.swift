import SwiftData
import XCTest
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
        let card = ReviewCard(
            factID: UUID().uuidString,
            category: .country,
            repetitionCount: repetitions,
            easeFactor: easeFactor
        )
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
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: .now, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 1)
    }

    func testStreak_reviewTwiceSameDay_remainsOne() {
        let d = freshDefaults()
        let today = Date.now
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: today, defaults: d)
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 1)
    }

    func testStreak_consecutiveDays_increments() throws {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let yesterday = try XCTUnwrap(cal.date(byAdding: .day, value: -1, to: today))
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: yesterday, defaults: d)
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 2)
    }

    func testStreak_threeDaysInARow() throws {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let d1 = try XCTUnwrap(cal.date(byAdding: .day, value: -2, to: today))
        let d2 = try XCTUnwrap(cal.date(byAdding: .day, value: -1, to: today))
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: d1, defaults: d)
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: d2, defaults: d)
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 3)
    }

    func testStreak_missedDay_resetsToOne() throws {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let twoDaysAgo = try XCTUnwrap(cal.date(byAdding: .day, value: -2, to: today))
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: twoDaysAgo, defaults: d)
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: today, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 1)
    }

    // MARK: - Per-language streak isolation

    func testStreak_isIndependentPerLanguage() throws {
        let d = freshDefaults()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let yesterday = try XCTUnwrap(cal.date(byAdding: .day, value: -1, to: today))
        let en = AppLocale.en.rawValue
        let ko = AppLocale.ko.rawValue

        // English: two consecutive days → streak 2.
        StreakTracker.recordReview(language: en, on: yesterday, defaults: d)
        StreakTracker.recordReview(language: en, on: today, defaults: d)
        // Korean: only today → streak 1.
        StreakTracker.recordReview(language: ko, on: today, defaults: d)

        XCTAssertEqual(StreakTracker.currentStreak(language: en, defaults: d), 2)
        XCTAssertEqual(StreakTracker.currentStreak(language: ko, defaults: d), 1)
    }

    func testStreak_languageWithNoReviewsIsZero() {
        let d = freshDefaults()
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: .now, defaults: d)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.de.rawValue, defaults: d), 0)
    }
}
