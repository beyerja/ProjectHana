import SwiftData
import XCTest
@testable import Hanahuac

/// Story 002 — per-quiz-mode progress isolation. A `CardStore` scoped to one `(language, quizMode)`
/// must never see, mutate, or collide with another mode's cards, and the `CardStoreProvider` must vend
/// one independent, seeded store per mode (with `typeCapital` Countries-only).
@MainActor
final class PerQuizModeProgressTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDownWithError() throws {
        container = nil
    }

    private func cardStore(_ mode: QuizModeID, language: String = "en") -> CardStore {
        CardStore(modelContext: container.mainContext, language: language, quizMode: mode.rawValue)
    }

    // MARK: - CardStore mode isolation

    func testCardStoreOnlySeesItsOwnMode() {
        let map = cardStore(.mapQuiz)
        let mc = cardStore(.multipleChoice)
        map.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(map.allCards.count, 1)
        XCTAssertTrue(mc.allCards.isEmpty, "The multipleChoice store must not see the mapQuiz card")
    }

    func testSameFactCoexistsAcrossModes() {
        let map = cardStore(.mapQuiz)
        let mc = cardStore(.multipleChoice)
        map.upsert(ReviewCard(factID: "us", category: .country))
        mc.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(map.allCards.filter { $0.factID == "us" }.count, 1)
        XCTAssertEqual(mc.allCards.filter { $0.factID == "us" }.count, 1)
    }

    func testGradingOneModeLeavesOtherModesUntouched() throws {
        let map = cardStore(.mapQuiz)
        let mc = cardStore(.multipleChoice)
        map.upsert(ReviewCard(factID: "us", category: .country))
        mc.upsert(ReviewCard(factID: "us", category: .country))

        // Grade the mapQuiz card (mutate its SR fields) and persist.
        let mapCard = try XCTUnwrap(map.allCards.first { $0.factID == "us" })
        mapCard.repetitionCount = 5
        mapCard.hasGraduated = true
        map.persistCardChanges()

        // The multipleChoice card for the same fact must be untouched (fresh).
        let mcCard = try XCTUnwrap(mc.allCards.first { $0.factID == "us" })
        XCTAssertEqual(mcCard.repetitionCount, 0, "Grading mapQuiz must not advance the multipleChoice card")
        XCTAssertFalse(mcCard.hasGraduated)
    }

    func testDeduplicateDoesNotCollapseAcrossModes() {
        let map = cardStore(.mapQuiz)
        let mc = cardStore(.multipleChoice)
        map.upsert(ReviewCard(factID: "us", category: .country))
        mc.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(map.deduplicate(), 0)
        XCTAssertEqual(mc.deduplicate(), 0)
        XCTAssertEqual(map.allCards.count, 1)
        XCTAssertEqual(mc.allCards.count, 1)
    }

    func testResetAllOnlyClearsActiveMode() {
        let map = cardStore(.mapQuiz)
        let mc = cardStore(.multipleChoice)
        map.upsert(ReviewCard(factID: "us", category: .country))
        mc.upsert(ReviewCard(factID: "us", category: .country))
        map.resetAll()
        XCTAssertTrue(map.allCards.isEmpty)
        XCTAssertEqual(mc.allCards.count, 1, "Resetting mapQuiz must not touch multipleChoice")
    }

    // MARK: - CardStoreProvider

    private func provider(language: String = "en") -> CardStoreProvider {
        CardStoreProvider(
            modelContext: container.mainContext,
            language: language,
            geographyData: GeographyDataLoader.load()
        )
    }

    func testProviderVendsIndependentSeededStorePerMode() {
        let p = provider()
        p.seedAllModes()
        let mapCount = p.store(for: .mapQuiz).allCards.count
        let mcCount = p.store(for: .multipleChoice).allCards.count
        XCTAssertGreaterThan(mapCount, 0)
        XCTAssertGreaterThan(mcCount, 0)
        // Each mode that serves all categories seeds the same full catalog independently.
        XCTAssertEqual(mapCount, mcCount)
    }

    func testTypeCapitalStoreIsCountriesOnly() {
        let p = provider()
        p.seedAllModes()
        let typeCapitalCards = p.store(for: .typeCapital).allCards
        XCTAssertFalse(typeCapitalCards.isEmpty)
        XCTAssertTrue(
            typeCapitalCards.allSatisfy { $0.cardCategory == .country },
            "typeCapital serves only Countries, so it must hold no river/mountain/sea cards"
        )
    }

    func testProviderAllCardsIsUnionAcrossModes() {
        let p = provider()
        p.seedAllModes()
        let perModeSum = QuizModeID.allCases
            .map { p.store(for: HomeQuizMode(quizModeID: $0)).allCards.count }
            .reduce(0, +)
        XCTAssertEqual(p.allCards.count, perModeSum, "Aggregate is the union of per-mode cards")
    }
}
