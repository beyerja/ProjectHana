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

    // MARK: - Reusable locale-parameterized isolation helper

    /// Assert that progress recorded under locale `a` stays fully isolated from locale `b`, and that a
    /// shared `factID`/day coexists across the two tracks. Per-language stories (002–009) only ADD a
    /// call with their new locale; they never change this helper or the existing test semantics.
    ///
    /// The helper seeds a card and a daily snapshot under `a`, then asserts `b`'s `CardStore`/
    /// `ProgressStatsStore` rows (keyed by `language` rawValue) stay empty, and that the same
    /// `factID`/day persists independently in both tracks once `b` records its own.
    private func assertProgressIsolated(
        _ a: AppLocale,
        _ b: AppLocale,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let factID = "shared-fact"
        let cardA = cardStore(a)
        let cardB = cardStore(b)
        cardA.upsert(ReviewCard(factID: factID, category: .country))
        XCTAssertEqual(cardA.allCards.count, 1, "\(a.rawValue) must hold its own card", file: file, line: line)
        XCTAssertTrue(
            cardB.allCards.isEmpty,
            "\(b.rawValue) cards must not see \(a.rawValue)'s card",
            file: file,
            line: line
        )

        let statsA = statsStore(a)
        let statsB = statsStore(b)
        statsA.recordSnapshot(cards: [reviewedCard(a)], streak: 1)
        XCTAssertEqual(
            statsA.allSnapshots.count,
            1,
            "\(a.rawValue) must hold its own snapshot",
            file: file,
            line: line
        )
        XCTAssertTrue(
            statsB.allSnapshots.isEmpty,
            "\(b.rawValue) snapshots must not see \(a.rawValue)'s snapshot",
            file: file,
            line: line
        )

        // The same factID/day coexists across tracks: once b records its own, both persist.
        cardB.upsert(ReviewCard(factID: factID, category: .country))
        statsB.recordSnapshot(cards: [reviewedCard(b, reps: 5)], streak: 2)
        XCTAssertEqual(
            cardA.allCards.filter { $0.factID == factID }.count,
            1,
            "\(a.rawValue) keeps its \(factID) card",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cardB.allCards.filter { $0.factID == factID }.count,
            1,
            "\(b.rawValue) keeps its \(factID) card",
            file: file,
            line: line
        )
        XCTAssertEqual(cardA.deduplicate(), 0, "cross-language same factID is not a duplicate", file: file, line: line)
        XCTAssertEqual(statsA.allSnapshots.count, 1, "\(a.rawValue) snapshot unchanged", file: file, line: line)
        XCTAssertEqual(statsB.allSnapshots.count, 1, "\(b.rawValue) snapshot unchanged", file: file, line: line)
    }

    /// Exercises the reusable helper on an existing locale pair, satisfying AC#3.
    func testProgressIsolationHelperOnExistingLocalePair() {
        assertProgressIsolated(.en, .ko)
    }

    /// Story 002: Spain Spanish keeps a progress track fully isolated from Mexican Spanish (they are
    /// distinct base codes, so the same factID/day coexists across the two).
    func testProgressIsolationForSpainSpanish() {
        assertProgressIsolated(.esES, .esMX)
    }

    /// Story 003: Catalan keeps a progress track fully isolated from its Spanish fallback target
    /// (es-ES); they are distinct language codes, so the same factID/day coexists across the two.
    func testProgressIsolationForCatalan() {
        assertProgressIsolated(.ca, .esES)
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

    // MARK: - Per-language breakdown summary (Story 006)

    private func freshDefaults() throws -> UserDefaults {
        let name = "test.summary.\(UUID().uuidString)"
        let d = try XCTUnwrap(UserDefaults(suiteName: name))
        d.removePersistentDomain(forName: name)
        return d
    }

    func testSummaryReflectsOnlyItsLanguageAndIsReadOnly() throws {
        let en = cardStore(.en)
        // One mastered card (reps high, ease high), one review card, one due card.
        let mastered = ReviewCard(factID: "m", category: .country, repetitionCount: 6, hasGraduated: true)
        let review = ReviewCard(factID: "r", category: .country, repetitionCount: 3, hasGraduated: true)
        let due = ReviewCard(
            factID: "d", category: .country, repetitionCount: 3,
            nextReviewDate: .distantPast, hasGraduated: true
        )
        en.upsert(mastered)
        en.upsert(review)
        en.upsert(due)
        // Korean gets a single card so it is non-empty but distinct.
        cardStore(.ko).upsert(ReviewCard(factID: "k", category: .country, repetitionCount: 1))

        let d = try freshDefaults()
        StreakTracker.recordReview(language: AppLocale.en.rawValue, on: .now, defaults: d)

        let enSummary = LanguageProgressSummary.make(for: .en, context: container.mainContext, defaults: d)
        XCTAssertEqual(enSummary.reviewed, 3)
        XCTAssertEqual(enSummary.mastered, 1)
        XCTAssertGreaterThanOrEqual(enSummary.due, 1)
        XCTAssertEqual(enSummary.streak, 1)

        let koSummary = LanguageProgressSummary.make(for: .ko, context: container.mainContext, defaults: d)
        XCTAssertEqual(koSummary.reviewed, 1)
        XCTAssertEqual(koSummary.mastered, 0)
        XCTAssertEqual(koSummary.streak, 0, "Korean has no streak; English's streak did not bleed in")

        // Computing summaries did not mutate any track.
        XCTAssertEqual(en.allCards.count, 3, "Summary computation is read-only")
    }

    func testSummaryAllCoversEveryLocaleWithZerosForEmpty() throws {
        let d = try freshDefaults()
        let summaries = LanguageProgressSummary.all(context: container.mainContext, defaults: d)
        XCTAssertEqual(summaries.count, AppLocale.allCases.count)
        XCTAssertTrue(summaries.allSatisfy { !$0.hasProgress }, "All languages empty → zeroed summaries")
    }
}
