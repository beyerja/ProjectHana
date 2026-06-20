import SwiftData
import XCTest
@testable import Hanahuac

/// Story 001 — the persisted progress models carry a `quizMode` dimension orthogonal to `language`.
/// These tests pin the model-level contract (defaults + distinct rows for the same `(factID,
/// language)` across modes). Store/migrator behavior is covered by later stories.
@MainActor
final class QuizModeDimensionTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self, DailyProgressSnapshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDownWithError() throws {
        container = nil
    }

    func testReviewCardDefaultsQuizModeToEmptyLegacySentinel() {
        let card = ReviewCard(factID: "us", category: .country)
        XCTAssertEqual(card.quizMode, "", "A card created without a mode is the legacy/unassigned sentinel")
    }

    func testSnapshotDefaultsQuizModeToEmptyAggregateSentinel() {
        let snapshot = DailyProgressSnapshot()
        XCTAssertEqual(snapshot.quizMode, "", "A snapshot without a mode is the aggregated/legacy rollup")
    }

    func testSameFactAndLanguageCoexistsAcrossQuizModes() throws {
        let context = container.mainContext
        let map = ReviewCard(factID: "us", language: "en", quizMode: QuizModeID.mapQuiz.rawValue, category: .country)
        let mc = ReviewCard(
            factID: "us",
            language: "en",
            quizMode: QuizModeID.multipleChoice.rawValue,
            category: .country
        )
        context.insert(map)
        context.insert(mc)
        try context.save()

        let all = try context.fetch(FetchDescriptor<ReviewCard>())
        let forUS = all.filter { $0.factID == "us" && $0.language == "en" }
        XCTAssertEqual(forUS.count, 2, "Same (factID, language) holds an independent card per quiz mode")
        XCTAssertEqual(Set(forUS.map(\.quizMode)), [QuizModeID.mapQuiz.rawValue, QuizModeID.multipleChoice.rawValue])
    }

    func testQuizModeIDRoundTripsThroughHomeQuizMode() {
        for id in QuizModeID.allCases {
            XCTAssertEqual(HomeQuizMode(quizModeID: id).quizModeID, id)
        }
    }

    func testMigrationTargetIsMapQuiz() {
        XCTAssertEqual(QuizModeID.legacyMigrationTarget, .mapQuiz)
    }
}
