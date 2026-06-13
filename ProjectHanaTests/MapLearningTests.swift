import XCTest
import SwiftData
@testable import ProjectHana

@MainActor
final class MapLearningTests: XCTestCase {
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

    // MARK: - MapLearningSession graduation mechanic

    func testMapLearningGraduatesAfterThreeCorrect() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allCountries: [])
        XCTAssertFalse(card.hasGraduated)
        session.handleTap(countryID: "c1")   // correct
        session.recordCorrect()
        session.handleTap(countryID: "c1")
        session.recordCorrect()
        XCTAssertFalse(card.hasGraduated)
        session.handleTap(countryID: "c1")
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
    }

    func testMapLearningWrongResetsStreak() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allCountries: [])
        session.handleTap(countryID: "c1")
        session.recordCorrect()
        session.handleTap(countryID: "c1")
        session.recordCorrect()
        XCTAssertEqual(card.consecutiveCorrect, 2)
        session.recordWrong()
        XCTAssertEqual(card.consecutiveCorrect, 0)
        XCTAssertFalse(card.hasGraduated)
    }

    func testMapLearningWrongRequiresThreeMoreCorrectToGraduate() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allCountries: [])
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

    func testMapLearningGraduationAppliesSM2() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allCountries: [])
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
        XCTAssertEqual(card.lastQualityScore, 4)
        XCTAssertGreaterThan(card.repetitionCount, 0)
    }

    func testMapLearningRefillsFromPoolOnGraduation() {
        let cards = makeCards(count: 11) // 10 active + 1 pending
        let session = MapLearningSession(newCards: cards, allCountries: [])
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 1)
        let current = session.current!
        current.consecutiveCorrect = MapLearningSession.requiredStreak - 1
        session.recordCorrect()
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 0)
    }

    func testMapLearningSessionFinishesWhenAllGraduate() {
        let cards = makeCards(count: 3)
        let session = MapLearningSession(newCards: cards, allCountries: [])
        while !session.isFinished {
            session.recordCorrect()
        }
        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.graduatedCount, 3)
    }

    func testMapLearningGraduatedCountIncrements() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allCountries: [])
        XCTAssertEqual(session.graduatedCount, 0)
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertEqual(session.graduatedCount, 1)
    }

    // MARK: - Active-set persistence

    func testActiveSetPersistenceSameIDsOnSecondConstruction() {
        let cards = makeCards(count: 5)
        let store = InMemoryActiveSetStore()

        let session1 = LearningSession(newCards: cards, category: .country, store: store)
        let ids1 = session1.activeSet.map(\.factID)
        XCTAssertFalse(ids1.isEmpty)

        let session2 = LearningSession(newCards: cards, category: .country, store: store)
        let ids2 = session2.activeSet.map(\.factID)
        XCTAssertEqual(ids1, ids2, "Second construction must resume the same active set")
    }

    func testActiveSetPersistenceFiltersGraduatedIDs() {
        let cards = makeCards(count: 3)
        let store = InMemoryActiveSetStore()

        let session1 = LearningSession(newCards: cards, category: .country, store: store)
        // Graduate one card outside the session to simulate it being marked done
        let firstID = session1.activeSet.first!.factID
        cards.first { $0.factID == firstID }!.hasGraduated = true

        // Remaining non-graduated cards
        let remaining = cards.filter { !$0.hasGraduated }
        let session2 = LearningSession(newCards: remaining, category: .country, store: store)
        XCTAssertFalse(session2.activeSet.contains { $0.factID == firstID },
                       "Graduated card must be excluded from rehydrated active set")
    }

    func testActiveSetPersistenceEmptyAfterFilterTriggersFreshDraw() {
        let cards = makeCards(count: 2)
        let store = InMemoryActiveSetStore()

        // First session — persists IDs
        _ = LearningSession(newCards: cards, category: .country, store: store)

        // Mark all persisted cards as graduated
        cards.forEach { $0.hasGraduated = true }

        // Second construction with only graduated cards — rehydrated set is empty → fresh draw
        // Provide new non-graduated cards
        let newCards = [(0..<2).map { makeCard(factID: "fresh\($0)") }].flatMap { $0 }
        let session2 = LearningSession(newCards: newCards, category: .country, store: store)
        XCTAssertFalse(session2.activeSet.isEmpty, "Fresh draw must produce a non-empty active set")
        let freshIDs = session2.activeSet.map(\.factID)
        XCTAssertTrue(freshIDs.allSatisfy { $0.hasPrefix("fresh") },
                      "Fresh draw must use new ungraduated cards")
    }

    func testActiveSetPersistenceUpdatedAfterGraduation() {
        let cards = makeCards(count: 5)
        let store = InMemoryActiveSetStore()
        let session = LearningSession(newCards: cards, category: .country, store: store)
        let initialStoredCount = store.load(for: .country).count
        XCTAssertGreaterThan(initialStoredCount, 0)

        let current = session.current!
        current.consecutiveCorrect = LearningSession.requiredStreak - 1
        session.recordCorrect()  // graduates the card

        let updatedStored = store.load(for: .country)
        XCTAssertFalse(updatedStored.contains(current.factID),
                       "Graduated card's ID must be removed from the persisted active set")
    }
}
