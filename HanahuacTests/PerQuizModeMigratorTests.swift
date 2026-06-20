import SwiftData
import XCTest
@testable import Hanahuac

/// Story 005 — the one-time per-quiz-mode migration: all pre-existing progress (the Map Tab Quiz) is
/// stamped onto `mapQuiz`; the other three modes start empty; daily snapshots stay aggregate; the
/// legacy per-language active set is copied into the `mapQuiz` key. Idempotent and fresh-install-safe.
@MainActor
final class PerQuizModeMigratorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let lang = AppLocale.en.rawValue

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    private func freshDefaults() throws -> UserDefaults {
        let name = "test.modeMigrator.\(UUID().uuidString)"
        let d = try XCTUnwrap(UserDefaults(suiteName: name))
        d.removePersistentDomain(forName: name)
        return d
    }

    func testLegacyCardsAreStampedMapQuiz() throws {
        context.insert(ReviewCard(factID: "us", category: .country, repetitionCount: 3))
        context.insert(ReviewCard(factID: "nile", category: .river))
        try context.save()

        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)

        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        XCTAssertTrue(
            cards.allSatisfy { $0.quizMode == QuizModeID.mapQuiz.rawValue },
            "All legacy cards are attributed to the Map Tab Quiz mode"
        )
        // Other modes have no cards.
        XCTAssertTrue(cards.allSatisfy { $0.quizMode != QuizModeID.multipleChoice.rawValue })
    }

    func testSnapshotsStayAggregateNotMapQuiz() throws {
        context.insert(DailyProgressSnapshot(day: .now, reviewsCompleted: 5))
        try context.save()

        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)

        let snaps = try context.fetch(FetchDescriptor<DailyProgressSnapshot>())
        XCTAssertTrue(
            snaps.allSatisfy(\.quizMode.isEmpty),
            "Legacy snapshots remain the mode-aggregated rollup (empty quizMode), not mapQuiz"
        )
        XCTAssertTrue(snaps.allSatisfy { $0.language == lang }, "but they still get the active language")
    }

    func testLegacyPerLanguageActiveSetCopiedToMapQuizKey() throws {
        let d = try freshDefaults()
        d.set(["us", "fr"], forKey: legacyPerLanguageActiveSetKey(language: lang, category: .country))

        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)

        let mapQuizKey = activeSetKey(language: lang, mode: .mapQuiz, category: .country)
        XCTAssertEqual(d.stringArray(forKey: mapQuizKey), ["us", "fr"], "Legacy active set copied into mapQuiz key")
        XCTAssertNil(
            d.stringArray(forKey: legacyPerLanguageActiveSetKey(language: lang, category: .country)),
            "Legacy per-language active-set key removed"
        )
        // Other modes start empty.
        XCTAssertNil(d.stringArray(forKey: activeSetKey(language: lang, mode: .multipleChoice, category: .country)))
    }

    func testIdempotentReRunDoesNotChangeData() throws {
        context.insert(ReviewCard(factID: "us", category: .country, repetitionCount: 3))
        try context.save()
        let d = try freshDefaults()

        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)
        // Simulate a card subsequently graded in a DIFFERENT mode — a re-run must not re-stamp it.
        context.insert(ReviewCard(
            factID: "de",
            language: lang,
            quizMode: QuizModeID.multipleChoice.rawValue,
            category: .country
        ))
        try context.save()

        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)

        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        let mc = try XCTUnwrap(cards.first { $0.factID == "de" })
        XCTAssertEqual(
            mc.quizMode,
            QuizModeID.multipleChoice.rawValue,
            "Re-run must not re-stamp non-empty-quizMode cards"
        )
        let us = try XCTUnwrap(cards.first { $0.factID == "us" })
        XCTAssertEqual(us.quizMode, QuizModeID.mapQuiz.rawValue)
    }

    func testFreshInstallUnaffected() throws {
        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: lang, defaults: d)
        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        XCTAssertTrue(cards.isEmpty, "No legacy data → nothing stamped")
        XCTAssertTrue(d.bool(forKey: ProgressMigrator.quizModeVersionKey), "Migration marked done")
    }
}
