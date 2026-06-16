import SwiftData
import XCTest
@testable import Hanahuac

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
        (0 ..< count).map { makeCard(factID: "c\($0)") }
    }

    // MARK: - MapLearningSession graduation mechanic

    func testMapLearningGraduatesAfterThreeCorrect() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allFeatures: [])
        XCTAssertFalse(card.hasGraduated)
        session.handleTap(featureID: "c1") // correct
        session.recordCorrect()
        session.handleTap(featureID: "c1")
        session.recordCorrect()
        XCTAssertFalse(card.hasGraduated)
        session.handleTap(featureID: "c1")
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
    }

    func testMapLearningWrongResetsStreak() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allFeatures: [])
        session.handleTap(featureID: "c1")
        session.recordCorrect()
        session.handleTap(featureID: "c1")
        session.recordCorrect()
        XCTAssertEqual(card.consecutiveCorrect, 2)
        session.recordWrong()
        XCTAssertEqual(card.consecutiveCorrect, 0)
        XCTAssertFalse(card.hasGraduated)
    }

    func testMapLearningWrongRequiresThreeMoreCorrectToGraduate() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allFeatures: [])
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
        let session = MapLearningSession(newCards: [card], allFeatures: [])
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
        XCTAssertEqual(card.lastQualityScore, 4)
        XCTAssertGreaterThan(card.repetitionCount, 0)
    }

    func testMapLearningRefillsFromPoolOnGraduation() throws {
        let cards = makeCards(count: 11) // 10 active + 1 pending
        let session = MapLearningSession(newCards: cards, allFeatures: [])
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 1)
        let current = try XCTUnwrap(session.current)
        current.consecutiveCorrect = MapLearningSession.requiredStreak - 1
        session.recordCorrect()
        XCTAssertEqual(session.activeSet.count, 10)
        XCTAssertEqual(session.pendingPool.count, 0)
    }

    func testMapLearningSessionFinishesWhenAllGraduate() {
        let cards = makeCards(count: 3)
        let session = MapLearningSession(newCards: cards, allFeatures: [])
        while !session.isFinished {
            session.recordCorrect()
        }
        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.graduatedCount, 3)
    }

    func testMapLearningGraduatedCountIncrements() {
        let card = makeCard()
        let session = MapLearningSession(newCards: [card], allFeatures: [])
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

    func testActiveSetPersistenceFiltersGraduatedIDs() throws {
        let cards = makeCards(count: 3)
        let store = InMemoryActiveSetStore()

        let session1 = LearningSession(newCards: cards, category: .country, store: store)
        // Graduate one card outside the session to simulate it being marked done
        let firstID = try XCTUnwrap(session1.activeSet.first?.factID)
        cards.first { $0.factID == firstID }?.hasGraduated = true

        // Remaining non-graduated cards
        let remaining = cards.filter { !$0.hasGraduated }
        let session2 = LearningSession(newCards: remaining, category: .country, store: store)
        XCTAssertFalse(
            session2.activeSet.contains { $0.factID == firstID },
            "Graduated card must be excluded from rehydrated active set"
        )
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
        let newCards = [(0 ..< 2).map { makeCard(factID: "fresh\($0)") }].flatMap { $0 }
        let session2 = LearningSession(newCards: newCards, category: .country, store: store)
        XCTAssertFalse(session2.activeSet.isEmpty, "Fresh draw must produce a non-empty active set")
        let freshIDs = session2.activeSet.map(\.factID)
        XCTAssertTrue(
            freshIDs.allSatisfy { $0.hasPrefix("fresh") },
            "Fresh draw must use new ungraduated cards"
        )
    }

    func testActiveSetPersistenceUpdatedAfterGraduation() throws {
        let cards = makeCards(count: 5)
        let store = InMemoryActiveSetStore()
        let session = LearningSession(newCards: cards, category: .country, store: store)
        let initialStoredCount = store.load(for: .country).count
        XCTAssertGreaterThan(initialStoredCount, 0)

        let current = try XCTUnwrap(session.current)
        current.consecutiveCorrect = LearningSession.requiredStreak - 1
        session.recordCorrect() // graduates the card

        let updatedStored = store.load(for: .country)
        XCTAssertFalse(
            updatedStored.contains(current.factID),
            "Graduated card's ID must be removed from the persisted active set"
        )
    }

    // MARK: - Wrong-click dual penalty (MapQuizSession)

    private func makeCountry(id: String) -> Country {
        Country(
            id: id,
            name: id,
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            capital: "Cap",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            continent: "EU",
            lat: 0,
            lon: 0
        )
    }

    func testMapQuizDualPenaltyAppliedToBothCards() throws {
        let quizzedCard = makeCard(factID: "correct")
        let tappedCard = makeCard(factID: "wrong")
        let countries = [makeCountry(id: "correct"), makeCountry(id: "wrong")]
        let session = MapQuizSession(cards: [quizzedCard, tappedCard], allFeatures: countries)
        // Determine which card is current after shuffle; tap the other one
        let currentID = try XCTUnwrap(session.currentCard?.factID)
        let otherID = currentID == "correct" ? "wrong" : "correct"
        let currentCard = currentID == "correct" ? quizzedCard : tappedCard
        let otherCard = currentID == "correct" ? tappedCard : quizzedCard
        session.handleTap(featureID: otherID)
        session.advance()
        // lastQualityScore is set to 1 for both cards on an incorrect answer
        XCTAssertEqual(currentCard.lastQualityScore, 1, "Quizzed card must receive quality=1 penalty")
        XCTAssertEqual(otherCard.lastQualityScore, 1, "Tapped card must receive quality=1 penalty")
    }

    func testMapQuizDualPenaltyNoopWhenTappedCardAbsent() {
        let quizzedCard = makeCard(factID: "correct")
        let countries = [makeCountry(id: "correct"), makeCountry(id: "absent")]
        // Only quizzedCard is in the deck; "absent" country has no card
        let session = MapQuizSession(cards: [quizzedCard], allFeatures: countries)
        session.handleTap(featureID: "absent")
        // Advance must not crash even though "absent" has no card in the deck
        XCTAssertNoThrow(session.advance())
        XCTAssertEqual(quizzedCard.lastQualityScore, 1)
    }

    // MARK: - Wrong-click dual streak-reset (MapLearningSession)

    func testMapLearningWrongResetsStreakOfTappedCard() throws {
        let correctCard = makeCard(factID: "correct")
        let tappedCard = makeCard(factID: "wrong")
        tappedCard.consecutiveCorrect = 2
        let countries = [makeCountry(id: "correct"), makeCountry(id: "wrong")]
        let session = MapLearningSession(newCards: [correctCard, tappedCard], allFeatures: countries)
        // Find which card is current and tap the other one
        let current = try XCTUnwrap(session.current)
        let otherID = current.factID == "correct" ? "wrong" : "correct"
        let otherCard = otherID == "wrong" ? tappedCard : correctCard
        otherCard.consecutiveCorrect = 2
        session.handleTap(featureID: otherID)
        session.recordWrong()
        XCTAssertEqual(otherCard.consecutiveCorrect, 0, "Tapped card's streak must be reset on wrong click")
    }

    func testMapLearningWrongStreakResetNoopWhenTappedCardAbsent() {
        let card = makeCard(factID: "correct")
        let countries = [makeCountry(id: "correct"), makeCountry(id: "absent")]
        let session = MapLearningSession(newCards: [card], allFeatures: countries)
        session.handleTap(featureID: "absent")
        // recordWrong must not crash when tapped country has no card in active set
        XCTAssertNoThrow(session.recordWrong())
    }

    // MARK: - MapLearningSession active-set persistence

    func testMapLearningPersistenceSameIDsOnSecondConstruction() {
        let cards = makeCards(count: 5)
        let store = InMemoryActiveSetStore()

        let session1 = MapLearningSession(
            newCards: cards,
            allFeatures: [],
            category: .country,
            store: store
        )
        let ids1 = session1.activeSet.map(\.factID)
        XCTAssertFalse(ids1.isEmpty)

        let session2 = MapLearningSession(
            newCards: cards,
            allFeatures: [],
            category: .country,
            store: store
        )
        let ids2 = session2.activeSet.map(\.factID)
        XCTAssertEqual(ids1, ids2, "Second construction must resume the same active set")
    }

    func testMapLearningPersistenceFiltersGraduatedIDs() throws {
        let cards = makeCards(count: 3)
        let store = InMemoryActiveSetStore()

        let session1 = MapLearningSession(
            newCards: cards,
            allFeatures: [],
            category: .country,
            store: store
        )
        // Graduate the first card outside the session
        let firstID = try XCTUnwrap(session1.activeSet.first?.factID)
        cards.first { $0.factID == firstID }?.hasGraduated = true

        let remaining = cards.filter { !$0.hasGraduated }
        let session2 = MapLearningSession(
            newCards: remaining,
            allFeatures: [],
            category: .country,
            store: store
        )
        XCTAssertFalse(
            session2.activeSet.contains { $0.factID == firstID },
            "Graduated card must be excluded from rehydrated active set"
        )
    }

    func testMapLearningPersistenceEmptyAfterFilterTriggersFreshDraw() {
        let cards = makeCards(count: 2)
        let store = InMemoryActiveSetStore()

        // First session — persists IDs
        _ = MapLearningSession(
            newCards: cards,
            allFeatures: [],
            category: .country,
            store: store
        )

        // Mark all persisted cards as graduated
        cards.forEach { $0.hasGraduated = true }

        // Second construction with only graduated cards — should draw fresh set
        let newCards = (0 ..< 2).map { makeCard(factID: "fresh\($0)") }
        let session2 = MapLearningSession(
            newCards: newCards,
            allFeatures: [],
            category: .country,
            store: store
        )
        XCTAssertFalse(session2.activeSet.isEmpty, "Fresh draw must produce a non-empty active set")
        let freshIDs = session2.activeSet.map(\.factID)
        XCTAssertTrue(
            freshIDs.allSatisfy { $0.hasPrefix("fresh") },
            "Fresh draw must use new ungraduated cards"
        )
    }

    func testMapLearningPersistenceUpdatedAfterGraduation() throws {
        let cards = makeCards(count: 5)
        let store = InMemoryActiveSetStore()
        let session = MapLearningSession(
            newCards: cards,
            allFeatures: [],
            category: .country,
            store: store
        )
        let initialStoredCount = store.load(for: .country).count
        XCTAssertGreaterThan(initialStoredCount, 0)

        let current = try XCTUnwrap(session.current)
        current.consecutiveCorrect = MapLearningSession.requiredStreak - 1
        session.recordCorrect() // graduates the card

        let updatedStored = store.load(for: .country)
        XCTAssertFalse(
            updatedStored.contains(current.factID),
            "Graduated card's ID must be removed from the persisted active set"
        )
    }

    func testMapLearningNoPersistenceWithoutStore() {
        // Without a store, two sessions with the same cards may produce different orderings
        // but the second session must still function without crashing.
        let cards = makeCards(count: 5)
        let session1 = MapLearningSession(newCards: cards, allFeatures: [])
        let session2 = MapLearningSession(newCards: cards, allFeatures: [])
        XCTAssertFalse(session1.activeSet.isEmpty)
        XCTAssertFalse(session2.activeSet.isEmpty)
    }
}
