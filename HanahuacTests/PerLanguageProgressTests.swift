import SwiftData
import XCTest
@testable import Hanahuac

/// Per-language progress isolation: a `CardStore`/`ProgressStatsStore` scoped to one language must
/// never see, mutate, or collide with another language's progress, and the same `factID`/`day` may
/// exist in two languages at once.
@MainActor
final class PerLanguageProgressTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDownWithError() throws {
        container = nil
    }

    private func cardStore(_ locale: AppLocale) -> CardStore {
        CardStore(modelContext: container.mainContext, language: locale.rawValue)
    }

    private func statsStore(_ locale: AppLocale) -> ProgressStatsStore {
        ProgressStatsStore(modelContext: container.mainContext, language: locale.rawValue)
    }

    /// A single reviewed card stamped for `locale` (so a stats snapshot computed from it counts a
    /// review). Keeps the per-language `recordSnapshot` call sites short and lint-clean.
    private func reviewedCard(_ locale: AppLocale, reps: Int = 3) -> ReviewCard {
        ReviewCard(factID: "f-\(locale.rawValue)", language: locale.rawValue, category: .country, repetitionCount: reps)
    }

    // MARK: - CardStore isolation

    func testCardStoreOnlySeesItsOwnLanguage() {
        let en = cardStore(.en)
        let ko = cardStore(.ko)
        en.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(en.allCards.count, 1)
        XCTAssertTrue(ko.allCards.isEmpty, "Korean store must not see the English card")
    }

    func testSameFactIDCoexistsAcrossLanguages() {
        let en = cardStore(.en)
        let ko = cardStore(.ko)
        en.upsert(ReviewCard(factID: "us", category: .country))
        ko.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(en.allCards.filter { $0.factID == "us" }.count, 1)
        XCTAssertEqual(ko.allCards.filter { $0.factID == "us" }.count, 1)
    }

    func testDeduplicateDoesNotCollapseAcrossLanguages() {
        let en = cardStore(.en)
        let ko = cardStore(.ko)
        en.upsert(ReviewCard(factID: "us", category: .country))
        ko.upsert(ReviewCard(factID: "us", category: .country))
        // Same factID, different languages → NOT duplicates.
        XCTAssertEqual(en.deduplicate(), 0)
        XCTAssertEqual(ko.deduplicate(), 0)
        XCTAssertEqual(en.allCards.count, 1)
        XCTAssertEqual(ko.allCards.count, 1)
    }

    func testSameLanguageDuplicateStillCollapses() {
        let en = cardStore(.en)
        en.upsert(ReviewCard(factID: "us", category: .country))
        en.upsert(ReviewCard(factID: "us", category: .country))
        XCTAssertEqual(en.allCards.count, 2)
        XCTAssertEqual(en.deduplicate(), 1)
        XCTAssertEqual(en.allCards.count, 1)
    }

    func testResetAllOnlyClearsActiveLanguage() {
        let en = cardStore(.en)
        let ko = cardStore(.ko)
        en.upsert(ReviewCard(factID: "us", category: .country))
        ko.upsert(ReviewCard(factID: "kr", category: .country))
        en.resetAll()
        XCTAssertTrue(en.allCards.isEmpty)
        XCTAssertEqual(ko.allCards.count, 1, "Resetting English must not touch Korean")
    }

    func testSeedingOneLanguageLeavesOtherEmptyThenSwitchBackRestores() throws {
        let geo = GeographyDataLoader.load()
        let expected = geo.countries.count + geo.rivers.count + geo.mountains.count + geo.seas.count

        // Seed English, then progress one card.
        let en = cardStore(.en)
        en.seedIfNeeded(with: geo)
        XCTAssertEqual(en.allCards.count, expected)
        let firstID = try XCTUnwrap(geo.countries.first).id
        let enCard = try XCTUnwrap(en.allCards.first { $0.factID == firstID })
        enCard.repetitionCount = 7
        enCard.hasGraduated = true
        try container.mainContext.save()

        // Switch to Korean: fresh start (0 progress), then seed it.
        let ko = cardStore(.ko)
        XCTAssertTrue(ko.allCards.isEmpty, "Korean starts empty (fresh track)")
        ko.seedIfNeeded(with: geo)
        XCTAssertEqual(ko.allCards.count, expected)
        let koCard = try XCTUnwrap(ko.allCards.first { $0.factID == firstID })
        XCTAssertEqual(koCard.repetitionCount, 0, "Korean is fresh; English progress did not bleed in")

        // Switch back to English: progress restored exactly.
        let enAgain = cardStore(.en)
        let restored = try XCTUnwrap(enAgain.allCards.first { $0.factID == firstID })
        XCTAssertEqual(restored.repetitionCount, 7)
        XCTAssertTrue(restored.hasGraduated)
        XCTAssertEqual(enAgain.allCards.count, expected, "English card count unchanged after KO seed")
    }

    // MARK: - ProgressStatsStore isolation

    func testSnapshotStoreOnlySeesItsOwnLanguage() {
        let en = statsStore(.en)
        let ko = statsStore(.ko)
        en.recordSnapshot(cards: [reviewedCard(.en)], streak: 1)
        XCTAssertEqual(en.allSnapshots.count, 1)
        XCTAssertTrue(ko.allSnapshots.isEmpty, "Korean stats must not see the English snapshot")
    }

    func testSameDayCoexistsAcrossLanguages() {
        let en = statsStore(.en)
        let ko = statsStore(.ko)
        en.recordSnapshot(cards: [reviewedCard(.en)], streak: 1)
        ko.recordSnapshot(cards: [reviewedCard(.ko, reps: 5)], streak: 2)
        // Same day, two languages → both snapshots persist independently.
        XCTAssertEqual(en.allSnapshots.count, 1)
        XCTAssertEqual(ko.allSnapshots.count, 1)
        XCTAssertEqual(en.allSnapshots.first?.streak, 1)
        XCTAssertEqual(ko.allSnapshots.first?.streak, 2)
        XCTAssertEqual(en.deduplicate(), 0, "Cross-language same-day is not a duplicate")
    }

    func testSwitchingLanguagePreservesEachStatsHistory() {
        let en = statsStore(.en)
        en.recordSnapshot(cards: [reviewedCard(.en)], streak: 9)

        // Korean records its own; English untouched.
        let ko = statsStore(.ko)
        ko.recordSnapshot(cards: [reviewedCard(.ko, reps: 1)], streak: 1)

        // Switch back to English: history restored exactly.
        let enAgain = statsStore(.en)
        XCTAssertEqual(enAgain.allSnapshots.count, 1)
        XCTAssertEqual(enAgain.allSnapshots.first?.streak, 9)
    }
}
