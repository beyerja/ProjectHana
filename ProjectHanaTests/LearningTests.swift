import XCTest
import SwiftData
@testable import ProjectHana

@MainActor
final class LearningTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(factID: String = "c1") -> ReviewCard {
        let card = ReviewCard(factID: factID, category: .country)
        container.mainContext.insert(card)
        return card
    }

    private func makeCards(count: Int) -> [ReviewCard] {
        (0..<count).map { makeCard(factID: "c\($0)") }
    }

    // MARK: - Graduation at 3 consecutive correct

    func testGraduatesAfterThreeCorrect() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        XCTAssertFalse(card.hasGraduated)
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertFalse(card.hasGraduated)
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
    }

    func testGraduatedCountIncrements() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        XCTAssertEqual(session.graduatedCount, 0)
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertEqual(session.graduatedCount, 1)
    }

    func testSessionFinishedWhenSingleCardGraduates() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertTrue(session.isFinished)
    }

    // MARK: - Wrong answer resets streak

    func testWrongResetsConsecutiveCorrect() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertEqual(card.consecutiveCorrect, 2)
        session.recordWrong()
        XCTAssertEqual(card.consecutiveCorrect, 0)
    }

    func testWrongKeepsCardInActiveSet() {
        let cards = makeCards(count: 2)
        let session = LearningSession(newCards: cards)
        let initialCount = session.activeSet.count
        session.recordWrong()
        XCTAssertEqual(session.activeSet.count, initialCount)
    }

    func testWrongRequiresThreeMoreCorrectToGraduate() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        session.recordCorrect()
        session.recordCorrect()
        session.recordWrong()
        XCTAssertFalse(card.hasGraduated)
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertFalse(card.hasGraduated)
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
    }

    // MARK: - Active set refill from pool

    func testRefillsFromPoolOnGraduation() {
        let cards = makeCards(count: 11) // 10 active + 1 pending
        let session = LearningSession(newCards: cards)
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 1)
        let current = session.current!
        // Graduate current card
        current.consecutiveCorrect = LearningSession.requiredStreak - 1
        session.recordCorrect()
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 0)
    }

    func testActiveSetShrinksBelowTenWhenPoolEmpty() {
        let cards = makeCards(count: 5)
        let session = LearningSession(newCards: cards)
        XCTAssertEqual(session.activeSet.count, 5)
        XCTAssertEqual(session.pendingPool.count, 0)
        let current = session.current!
        current.consecutiveCorrect = LearningSession.requiredStreak - 1
        session.recordCorrect()
        XCTAssertEqual(session.activeSet.count, 4)
    }

    // MARK: - Session completion

    func testFinishedAfterAllGraduate() {
        let cards = makeCards(count: 3)
        let session = LearningSession(newCards: cards)
        while !session.isFinished {
            session.recordCorrect()
        }
        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.graduatedCount, 3)
    }

    func testCurrentIsNilWhenFinished() {
        let card = makeCard()
        let session = LearningSession(newCards: [card])
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertNil(session.current)
    }

    // MARK: - dueCards excludes ungraduated cards

    func testDueCardsExcludesNewCards() throws {
        let store = CardStore(modelContext: container.mainContext)
        store.upsert(ReviewCard(factID: "new1", category: .country))
        store.upsert(ReviewCard(factID: "new2", category: .country))
        let due = store.dueCards()
        XCTAssertTrue(due.isEmpty, "Ungraduated cards must not appear in dueCards")
    }

    func testDueCardsIncludesGraduatedCards() throws {
        let store = CardStore(modelContext: container.mainContext)
        let card = ReviewCard(factID: "grad1", category: .country, hasGraduated: true)
        store.upsert(card)
        let due = store.dueCards()
        XCTAssertEqual(due.count, 1)
    }

    // MARK: - newCards return

    func testNewCardsReturnsOnlyUngraduated() throws {
        let store = CardStore(modelContext: container.mainContext)
        store.upsert(ReviewCard(factID: "new1", category: .country))
        store.upsert(ReviewCard(factID: "grad1", category: .country, hasGraduated: true))
        let newCards = store.newCards()
        XCTAssertEqual(newCards.count, 1)
        XCTAssertEqual(newCards.first?.factID, "new1")
    }

    func testNewCardsEmptyWhenAllGraduated() throws {
        let store = CardStore(modelContext: container.mainContext)
        store.upsert(ReviewCard(factID: "grad1", category: .country, hasGraduated: true))
        XCTAssertTrue(store.newCards().isEmpty)
    }
}
