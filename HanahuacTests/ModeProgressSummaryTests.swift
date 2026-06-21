import SwiftData
import XCTest
@testable import Hanahuac

/// Story 006 — the per-mode breakdown summary reads each quiz mode's progress independently within the
/// active language, so the Stats screen can show a per-mode breakdown alongside the aggregated default.
@MainActor
final class ModeProgressSummaryTests: XCTestCase {
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

    private func card(
        _ factID: String,
        mode: QuizModeID,
        category: CardCategory = .country,
        reps: Int = 3
    ) -> ReviewCard {
        ReviewCard(factID: factID, language: lang, quizMode: mode.rawValue, category: category, repetitionCount: reps)
    }

    func testOneSummaryPerModeInDisplayOrder() {
        let summaries = ModeProgressSummary.all(language: lang, context: context)
        XCTAssertEqual(summaries.map(\.mode), QuizModeID.allCases)
        XCTAssertEqual(summaries.first?.mode, .mapQuiz)
    }

    func testFactGradedInOneModeShowsUnderThatModeOnly() throws {
        context.insert(card("us", mode: .mapQuiz))
        try context.save()

        let summaries = ModeProgressSummary.all(language: lang, context: context)
        let map = try XCTUnwrap(summaries.first { $0.mode == .mapQuiz })
        let mc = try XCTUnwrap(summaries.first { $0.mode == .multipleChoice })
        XCTAssertEqual(map.reviewed, 1, "The graded fact counts under mapQuiz")
        XCTAssertEqual(mc.reviewed, 0, "...and not under multipleChoice")
    }

    func testEmptyModesYieldZeroedSummaries() {
        let summaries = ModeProgressSummary.all(language: lang, context: context)
        XCTAssertTrue(summaries.allSatisfy { $0.reviewed == 0 && $0.mastered == 0 && $0.due == 0 })
    }

    func testSummaryIgnoresOtherLanguages() throws {
        // A Korean mapQuiz card must not appear in the English mapQuiz summary.
        context.insert(ReviewCard(
            factID: "kr",
            language: AppLocale.ko.rawValue,
            quizMode: QuizModeID.mapQuiz.rawValue,
            category: .country,
            repetitionCount: 5
        ))
        try context.save()

        let summaries = ModeProgressSummary.all(language: lang, context: context)
        let map = try XCTUnwrap(summaries.first { $0.mode == .mapQuiz })
        XCTAssertEqual(map.reviewed, 0, "English mapQuiz summary must not count the Korean card")
    }
}
