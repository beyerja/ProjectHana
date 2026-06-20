import SwiftData
import XCTest
@testable import Hanahuac

@MainActor
final class CardDedupTests: XCTestCase {
    private var container: ModelContainer!
    private var store: CardStore!
    private var geoData: GeographyData!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        store = CardStore(modelContext: container.mainContext, language: AppLocale.en.rawValue)
        geoData = GeographyDataLoader.load()
    }

    override func tearDownWithError() throws {
        store.resetAll()
        container = nil
        store = nil
        geoData = nil
    }

    // MARK: - Dedup by factID

    func testDeduplicateCollapsesDuplicatesByFactID() {
        let plain = ReviewCard(factID: "us", category: .country)
        let alsoPlain = ReviewCard(factID: "us", category: .country)
        store.upsert(plain)
        store.upsert(alsoPlain)
        XCTAssertEqual(store.allCards.count, 2)

        let removed = store.deduplicate()

        XCTAssertEqual(removed, 1)
        XCTAssertEqual(store.allCards.filter { $0.factID == "us" }.count, 1)
    }

    func testDeduplicatePreservesMostProgressedCard() throws {
        let fresh = ReviewCard(factID: "nile", category: .river)
        let progressed = ReviewCard(
            factID: "nile",
            category: .river,
            repetitionCount: 4,
            intervalDays: 30,
            consecutiveCorrect: 3,
            hasGraduated: true
        )
        store.upsert(fresh)
        store.upsert(progressed)

        store.deduplicate()

        let survivors = store.allCards.filter { $0.factID == "nile" }
        XCTAssertEqual(survivors.count, 1)
        let winner = try XCTUnwrap(survivors.first)
        XCTAssertTrue(winner.hasGraduated, "Graduated/most-progressed card must survive")
        XCTAssertEqual(winner.repetitionCount, 4)
        XCTAssertEqual(winner.consecutiveCorrect, 3)
    }

    func testDeduplicateNoOpWhenNoDuplicates() {
        store.upsert(ReviewCard(factID: "a", category: .country))
        store.upsert(ReviewCard(factID: "b", category: .country))
        let removed = store.deduplicate()
        XCTAssertEqual(removed, 0)
        XCTAssertEqual(store.allCards.count, 2)
    }

    // MARK: - Seeding is per-factID idempotent

    func testEmptySeedProducesExactlyOneCardPerFact() {
        store.seedIfNeeded(with: geoData)
        let expected = geoData.countries.count + geoData.rivers.count +
            geoData.mountains.count + geoData.seas.count
        XCTAssertEqual(store.allCards.count, expected)

        // Exactly one per factID.
        let byFact = Dictionary(grouping: store.allCards, by: \.factID)
        XCTAssertTrue(
            byFact.values.allSatisfy { $0.count == 1 },
            "No factID should have more than one card"
        )
    }

    func testReseedingFullStoreAddsNoDuplicates() {
        store.seedIfNeeded(with: geoData)
        let count = store.allCards.count
        store.seedIfNeeded(with: geoData)
        XCTAssertEqual(store.allCards.count, count)
    }

    func testPartialSeedFillsOnlyMissingFactsWithoutDuplicating() throws {
        // Pre-insert one card that the catalog also contains.
        let firstCountry = try XCTUnwrap(geoData.countries.first)
        store.upsert(ReviewCard(factID: firstCountry.id, category: .country, repetitionCount: 9, hasGraduated: true))

        store.seedIfNeeded(with: geoData)

        let expected = geoData.countries.count + geoData.rivers.count +
            geoData.mountains.count + geoData.seas.count
        XCTAssertEqual(store.allCards.count, expected, "Partial seed must fill only missing facts")

        let matches = store.allCards.filter { $0.factID == firstCountry.id }
        XCTAssertEqual(matches.count, 1, "Pre-existing fact must not be duplicated")
        XCTAssertEqual(matches.first?.repetitionCount, 9, "Pre-existing progress must be preserved")
    }

    // MARK: - CloudKit compatibility: model-level defaults

    func testModelHasDefaultsForCloudKitCompatibility() {
        // A card created via the SwiftData default initializer path should carry sane defaults.
        let card = ReviewCard(factID: "x", category: .sea)
        XCTAssertEqual(card.easeFactor, 2.5, accuracy: 0.001)
        XCTAssertEqual(card.intervalDays, 0)
        XCTAssertEqual(card.repetitionCount, 0)
        XCTAssertFalse(card.hasGraduated)
        XCTAssertNil(card.lastQualityScore)
    }
}
