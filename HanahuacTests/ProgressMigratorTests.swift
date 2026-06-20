import SwiftData
import XCTest
@testable import Hanahuac

/// One-time upgrade migration: pre-existing global progress (empty-language SwiftData rows + legacy
/// un-namespaced key-value data) is attributed to the active language, idempotently.
@MainActor
final class ProgressMigratorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

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
        let name = "test.migrator.\(UUID().uuidString)"
        let d = try XCTUnwrap(UserDefaults(suiteName: name))
        d.removePersistentDomain(forName: name)
        return d
    }

    // MARK: - SwiftData rows

    func testStampsEmptyLanguageRowsWithActiveLanguage() throws {
        // Legacy global rows (language == "").
        context.insert(ReviewCard(factID: "us", category: .country, repetitionCount: 3))
        context.insert(ReviewCard(factID: "nile", category: .river))
        context.insert(DailyProgressSnapshot(day: .now, reviewsCompleted: 5))
        try context.save()

        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)

        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        XCTAssertTrue(cards.allSatisfy { $0.language == AppLocale.en.rawValue })
        let snaps = try context.fetch(FetchDescriptor<DailyProgressSnapshot>())
        XCTAssertTrue(snaps.allSatisfy { $0.language == AppLocale.en.rawValue })
    }

    func testDoesNotRestampAlreadyLanguagedRows() throws {
        // A row already attributed to Korean must not be overwritten when migrating to English.
        context.insert(ReviewCard(factID: "kr", language: AppLocale.ko.rawValue, category: .country))
        context.insert(ReviewCard(factID: "us", category: .country)) // legacy, empty language
        try context.save()

        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)

        let byFact = try Dictionary(
            uniqueKeysWithValues: context.fetch(FetchDescriptor<ReviewCard>()).map { ($0.factID, $0.language) }
        )
        XCTAssertEqual(byFact["kr"], AppLocale.ko.rawValue, "Existing Korean row preserved")
        XCTAssertEqual(byFact["us"], AppLocale.en.rawValue, "Legacy row attributed to active language")
    }

    func testIsIdempotent_runningTwiceDoesNotDuplicateOrChange() throws {
        context.insert(ReviewCard(factID: "us", category: .country, repetitionCount: 2))
        try context.save()

        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)
        // A second run with a DIFFERENT active language must be a no-op (version flag set).
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.ko.rawValue, defaults: d)

        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        XCTAssertEqual(cards.count, 1, "No duplication")
        XCTAssertEqual(cards.first?.language, AppLocale.en.rawValue, "Second run did not re-stamp to Korean")
    }

    // MARK: - Key-value progress

    func testMigratesLegacyStreakToActiveLanguage() throws {
        let d = try freshDefaults()
        d.set(7, forKey: StreakTracker.legacyStreakKey)
        d.set(Date.now, forKey: StreakTracker.legacyLastReviewKey)

        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)

        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 7)
        XCTAssertNil(d.object(forKey: StreakTracker.legacyStreakKey), "Legacy streak key removed")
    }

    func testMigratesLegacyActiveSetToActiveLanguageMapQuizMode() throws {
        let d = try freshDefaults()
        d.set(["us", "fr"], forKey: legacyActiveSetKey(for: .country))

        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)

        // The combined migration moves the legacy un-namespaced active set all the way to the active
        // language's MAP QUIZ per-mode key: per-language step → activeSet.en.country, then per-mode
        // step → activeSet.en.mapQuiz.country (all legacy progress was the Map Tab Quiz).
        let mapQuiz = UserDefaultsActiveSetStore(language: AppLocale.en.rawValue, mode: .mapQuiz, defaults: d)
        XCTAssertEqual(mapQuiz.load(for: .country), ["us", "fr"])
        XCTAssertNil(d.stringArray(forKey: legacyActiveSetKey(for: .country)), "Legacy active-set key removed")
        XCTAssertNil(
            d.stringArray(forKey: legacyPerLanguageActiveSetKey(language: AppLocale.en.rawValue, category: .country)),
            "Intermediate per-language active-set key consumed by the per-mode step"
        )
    }

    func testFreshInstallWithNoLegacyDataIsNoOp() throws {
        let d = try freshDefaults()
        ProgressMigrator.migrateIfNeeded(context: context, activeLanguage: AppLocale.en.rawValue, defaults: d)

        let cards = try context.fetch(FetchDescriptor<ReviewCard>())
        XCTAssertTrue(cards.isEmpty)
        XCTAssertEqual(StreakTracker.currentStreak(language: AppLocale.en.rawValue, defaults: d), 0)
        XCTAssertTrue(d.bool(forKey: ProgressMigrator.versionKey), "Migration marked done")
    }
}
