import XCTest
import SwiftData
@testable import Hanahuac

@MainActor
final class CardStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: CardStore!
    private var geoData: GeographyData!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = CardStore(modelContext: container.mainContext)
        geoData = GeographyDataLoader.load()
    }

    override func tearDownWithError() throws {
        store.resetAll()
        container = nil
        store = nil
    }

    func testSeedingCountMatchesDataset() {
        store.seedIfNeeded(with: geoData)
        let expected = geoData.countries.count + geoData.rivers.count +
                       geoData.mountains.count + geoData.seas.count
        XCTAssertEqual(store.allCards.count, expected)
    }

    func testSeedingIsIdempotent() {
        store.seedIfNeeded(with: geoData)
        let countAfterFirst = store.allCards.count
        store.seedIfNeeded(with: geoData)
        XCTAssertEqual(store.allCards.count, countAfterFirst, "Second seed should not add cards")
    }

    func testUpsertPersistsCard() {
        let card = ReviewCard(factID: "test-fact", category: .country)
        store.upsert(card)
        XCTAssertEqual(store.allCards.count, 1)
    }

    func testDueCardsReturnsOverdueOnly() {
        let due = ReviewCard(factID: "due", category: .country, nextReviewDate: .distantPast, hasGraduated: true)
        let future = ReviewCard(factID: "future", category: .country, nextReviewDate: .distantFuture, hasGraduated: true)
        store.upsert(due)
        store.upsert(future)
        let dueCards = store.dueCards()
        XCTAssertTrue(dueCards.contains(where: { $0.factID == "due" }))
        XCTAssertFalse(dueCards.contains(where: { $0.factID == "future" }))
    }

    func testDueCardsFiltersByCategory() {
        let countryCard = ReviewCard(factID: "us", category: .country, nextReviewDate: .distantPast, hasGraduated: true)
        let riverCard = ReviewCard(factID: "nile", category: .river, nextReviewDate: .distantPast, hasGraduated: true)
        store.upsert(countryCard)
        store.upsert(riverCard)
        let countryDue = store.dueCards(for: .country)
        XCTAssertTrue(countryDue.allSatisfy { $0.cardCategory == .country })
        XCTAssertEqual(countryDue.count, 1)
    }

    func testResetAllClearsCards() {
        store.seedIfNeeded(with: geoData)
        XCTAssertGreaterThan(store.allCards.count, 0)
        store.resetAll()
        XCTAssertEqual(store.allCards.count, 0)
    }

    func testDefaultEaseFactorIs2Point5() {
        let card = ReviewCard(factID: "de", category: .country)
        XCTAssertEqual(card.easeFactor, 2.5, accuracy: 0.001)
    }

    func testDefaultIntervalIsZero() {
        let card = ReviewCard(factID: "de", category: .country)
        XCTAssertEqual(card.intervalDays, 0)
    }
}
