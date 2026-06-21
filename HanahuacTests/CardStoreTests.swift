import SwiftData
import XCTest
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
        store = CardStore(modelContext: container.mainContext, language: AppLocale.en.rawValue)
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
        let future = ReviewCard(
            factID: "future",
            category: .country,
            nextReviewDate: .distantFuture,
            hasGraduated: true
        )
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

    // MARK: - Revision signal (Observation regression guard)

    func testUpsertBumpsRevision() {
        let before = store.revision
        store.upsert(ReviewCard(factID: "rev-upsert", category: .country))
        XCTAssertGreaterThan(store.revision, before)
    }

    func testResetAllBumpsRevision() {
        store.seedIfNeeded(with: geoData)
        let before = store.revision
        store.resetAll()
        XCTAssertGreaterThan(store.revision, before)
    }

    func testSeedIfNeededBumpsRevision() {
        let before = store.revision
        store.seedIfNeeded(with: geoData)
        XCTAssertGreaterThan(store.revision, before)
    }

    func testPersistCardChangesBumpsRevision() {
        let before = store.revision
        store.persistCardChanges()
        XCTAssertGreaterThan(store.revision, before)
    }

    func testPersistCardChangesPersistsCardMutation() throws {
        // Insert and persist a card through the store so it is established on the shared context.
        let card = ReviewCard(factID: "persist-fact", category: .country)
        store.upsert(card)
        XCTAssertFalse(card.hasGraduated)

        // Mutate the live card in place (as a quiz session does while grading), then route the save
        // through the new entry point rather than relying on autosave.
        card.consecutiveCorrect = 3
        card.hasGraduated = true
        store.persistCardChanges()

        // Re-read through a fresh store on the same context to confirm the mutation was flushed.
        let freshStore = CardStore(modelContext: container.mainContext, language: AppLocale.en.rawValue)
        let reread = try XCTUnwrap(freshStore.allCards.first { $0.factID == "persist-fact" })
        XCTAssertTrue(reread.hasGraduated)
        XCTAssertEqual(reread.consecutiveCorrect, 3)
    }

    func testPersistCardChangesUpdatesPileCountsTheRevisionDependencyReadsFrom() {
        // A fresh card is "new" (not graduated) and so appears in newCards; it is not due. This is the
        // exact data path PilePickerView's `_ = cardStore.revision` read depends on: when a quiz grades
        // the card out of the new pile, persistCardChanges() must both bump revision and change the
        // counts the pile picker fetches.
        let card = ReviewCard(factID: "pile-shift", category: .country)
        store.upsert(card)
        XCTAssertEqual(store.newCards(for: .country).count, 1, "Card should start in the new pile")
        XCTAssertEqual(store.dueCards(for: .country).count, 0, "Card should not start in the pending pile")

        // Grade the card out of both piles: graduating it removes it from new, and a future review date
        // keeps it out of pending.
        card.hasGraduated = true
        card.nextReviewDate = .distantFuture
        let before = store.revision
        store.persistCardChanges()

        XCTAssertGreaterThan(store.revision, before, "persistCardChanges must bump the revision signal")
        XCTAssertEqual(store.newCards(for: .country).count, 0, "Graduated card should leave the new pile")
        XCTAssertEqual(store.dueCards(for: .country).count, 0, "Future-dated card should not be pending")

        // Confirm the mutation is durable via a fresh store re-read on the same context.
        let freshStore = CardStore(modelContext: container.mainContext, language: AppLocale.en.rawValue)
        XCTAssertEqual(freshStore.newCards(for: .country).count, 0)
    }

    func testDeduplicateBumpsRevisionWhenDuplicatesRemoved() throws {
        // Insert two raw cards sharing a factID for the active language so deduplicate has work to do.
        let lang = AppLocale.en.rawValue
        container.mainContext.insert(ReviewCard(factID: "dup", language: lang, category: .country))
        container.mainContext.insert(ReviewCard(factID: "dup", language: lang, category: .country))
        try container.mainContext.save()
        let before = store.revision
        let removed = store.deduplicate()
        XCTAssertEqual(removed, 1)
        XCTAssertGreaterThan(store.revision, before)
    }
}
