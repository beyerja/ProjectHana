import XCTest
import SwiftData
@testable import ProjectHana

@MainActor
final class SM2SchedulerTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(repetition: Int = 0, easeFactor: Double = 2.5, interval: Int = 0) -> ReviewCard {
        let card = ReviewCard(factID: "test", category: .country)
        card.repetitionCount = repetition
        card.easeFactor = easeFactor
        card.intervalDays = interval
        container.mainContext.insert(card)
        return card
    }

    // MARK: – First review

    func testFirstReviewGoodSetsInterval1() {
        let card = makeCard()
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        XCTAssertEqual(result.newRepetitionCount, 1)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    func testFirstReviewEasySetsInterval1() {
        let card = makeCard()
        let result = SM2Scheduler.schedule(card: card, quality: 5)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    // MARK: – Second review

    func testSecondReviewGoodSetsInterval6() {
        let card = makeCard(repetition: 1, interval: 1)
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        XCTAssertEqual(result.newRepetitionCount, 2)
        XCTAssertEqual(result.newIntervalDays, 6)
    }

    // MARK: – Subsequent reviews

    func testThirdReviewUsesEaseFactor() {
        let card = makeCard(repetition: 2, easeFactor: 2.5, interval: 6)
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        // interval = round(6 * newEF). EF for quality 4: 2.5 + (0.1 - 1*(0.08 + 1*0.02)) = 2.5
        XCTAssertEqual(result.newIntervalDays, 15) // round(6 * 2.5) = 15
        XCTAssertEqual(result.newRepetitionCount, 3)
    }

    // MARK: – Failed recall

    func testQuality0ResetsRepetition() {
        let card = makeCard(repetition: 5, easeFactor: 2.5, interval: 30)
        let result = SM2Scheduler.schedule(card: card, quality: 0)
        XCTAssertEqual(result.newRepetitionCount, 0)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    func testQuality1ResetsRepetition() {
        let card = makeCard(repetition: 3, interval: 10)
        let result = SM2Scheduler.schedule(card: card, quality: 1)
        XCTAssertEqual(result.newRepetitionCount, 0)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    func testQuality2ResetsRepetition() {
        let card = makeCard(repetition: 2, interval: 6)
        let result = SM2Scheduler.schedule(card: card, quality: 2)
        XCTAssertEqual(result.newRepetitionCount, 0)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    // MARK: – Ease factor updates

    func testEaseFactorIncreasesForQuality5() {
        let card = makeCard(easeFactor: 2.5)
        let result = SM2Scheduler.schedule(card: card, quality: 5)
        XCTAssertGreaterThan(result.newEaseFactor, 2.5)
    }

    func testEaseFactorUnchangedForQuality4() {
        let card = makeCard(easeFactor: 2.5)
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        XCTAssertEqual(result.newEaseFactor, 2.5, accuracy: 0.001)
    }

    func testEaseFactorDecreasesForQuality3() {
        let card = makeCard(easeFactor: 2.5)
        let result = SM2Scheduler.schedule(card: card, quality: 3)
        XCTAssertLessThan(result.newEaseFactor, 2.5)
    }

    func testEaseFactorFloorAt1Point3() {
        let card = makeCard(easeFactor: 1.3)
        let result = SM2Scheduler.schedule(card: card, quality: 0)
        XCTAssertEqual(result.newEaseFactor, 1.3, accuracy: 0.001)
    }

    func testEaseFactorNeverDropsBelowFloor() {
        var card = makeCard(easeFactor: 2.5)
        for _ in 0..<20 {
            let result = SM2Scheduler.schedule(card: card, quality: 0)
            card.easeFactor = result.newEaseFactor
            XCTAssertGreaterThanOrEqual(card.easeFactor, 1.3)
        }
    }

    // MARK: – Quality 5 streak

    func testQuality5StreakGrowsInterval() {
        var card = makeCard(easeFactor: 2.5, interval: 0)
        var lastInterval = 0
        for rep in 0..<5 {
            let result = SM2Scheduler.schedule(card: card, quality: 5)
            if rep >= 2 {
                XCTAssertGreaterThan(result.newIntervalDays, lastInterval,
                    "Interval should grow on rep \(rep)")
            }
            card.repetitionCount = result.newRepetitionCount
            card.easeFactor = result.newEaseFactor
            card.intervalDays = result.newIntervalDays
            lastInterval = result.newIntervalDays
        }
    }

    // MARK: – Boundary values

    func testQuality0IsValid() {
        let card = makeCard()
        let result = SM2Scheduler.schedule(card: card, quality: 0)
        XCTAssertEqual(result.newIntervalDays, 1)
    }

    func testQuality5IsValid() {
        let card = makeCard()
        let result = SM2Scheduler.schedule(card: card, quality: 5)
        XCTAssertEqual(result.newIntervalDays, 1)
        XCTAssertGreaterThan(result.newEaseFactor, 2.5)
    }

    // MARK: – Apply

    func testApplyMutatesCard() {
        let card = makeCard(repetition: 1, easeFactor: 2.5, interval: 1)
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        SM2Scheduler.apply(result, to: card, quality: 4)
        XCTAssertEqual(card.repetitionCount, result.newRepetitionCount)
        XCTAssertEqual(card.easeFactor, result.newEaseFactor, accuracy: 0.001)
        XCTAssertEqual(card.intervalDays, result.newIntervalDays)
        XCTAssertEqual(card.lastQualityScore, 4)
    }
}
