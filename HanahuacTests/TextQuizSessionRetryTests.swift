import SwiftData
import XCTest
@testable import Hanahuac

@MainActor
final class TextQuizSessionRetryTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDownWithError() throws {
        container = nil
    }

    // MARK: - Helpers

    private func makeCard(factID: String = "x") -> ReviewCard {
        let card = ReviewCard(factID: factID, category: .country)
        container.mainContext.insert(card)
        return card
    }

    private func makeQuestion(factID: String) -> TextQuestion {
        TextQuestion(card: makeCard(factID: factID), prompt: "Q-\(factID)", correctAnswer: "A-\(factID)")
    }

    /// Submit a wrong answer for the current question and advance.
    private func answerWrong(session: TextQuizSession) throws {
        let q = try XCTUnwrap(session.current)
        session.checkAnswer("__wrong__-\(q.correctAnswer)")
        session.advance()
    }

    /// Submit the correct answer for the current question and advance.
    private func answerCorrect(session: TextQuizSession) throws {
        let q = try XCTUnwrap(session.current)
        session.checkAnswer(q.correctAnswer)
        session.advance()
    }

    // MARK: - Tests

    /// (a) A wrong answer reinserts the question — session not finished, question appears again.
    func testRetry_wrongAnswerReinserts_sessionNotFinished_questionAppearsAgain() throws {
        let session = TextQuizSession(questions: [makeQuestion(factID: "a")])
        let firstQuestion = try XCTUnwrap(session.current)
        try answerWrong(session: session)
        XCTAssertFalse(session.isFinished, "Session must not be finished after one wrong answer")
        let nextQuestion = try XCTUnwrap(session.current)
        XCTAssertEqual(
            nextQuestion.correctAnswer,
            firstQuestion.correctAnswer,
            "The reinserted question must appear again as current"
        )
    }

    /// (b) After one wrong answer the session is NOT finished.
    func testRetry_notFinishedAfterOneWrongAnswer() throws {
        let session = TextQuizSession(questions: [makeQuestion(factID: "a"), makeQuestion(factID: "b")])
        try answerWrong(session: session)
        XCTAssertFalse(session.isFinished, "Session must not finish after a single wrong answer")
    }

    /// (c) Session finishes only after all questions answered correctly at least once.
    func testRetry_finishesOnlyAfterAllQuestionsCorrect() throws {
        let session = TextQuizSession(questions: [makeQuestion(factID: "a"), makeQuestion(factID: "b")])
        var iterations = 0
        while !session.isFinished {
            try answerCorrect(session: session)
            iterations += 1
            XCTAssertLessThan(iterations, 20, "Session should finish in a bounded number of steps")
        }
        XCTAssertTrue(session.isFinished, "Session must be finished after all questions answered correctly")
    }

    /// (d) A question answered wrong N times then correct contributes N+1 to reviewedCount.
    func testRetry_reviewedCountCountsAllAttempts() throws {
        let session = TextQuizSession(questions: [makeQuestion(factID: "a")])
        let wrongAnswers = 3
        for _ in 0 ..< wrongAnswers {
            try answerWrong(session: session)
        }
        try answerCorrect(session: session)
        XCTAssertEqual(
            session.reviewedCount,
            wrongAnswers + 1,
            "reviewedCount must equal total advance() calls (wrong + correct)"
        )
    }

    /// (e) correctCount equals totalQuestions when session finishes.
    func testRetry_correctCountEqualsTotalQuestionsOnFinish() throws {
        let session = TextQuizSession(questions: [
            makeQuestion(factID: "a"),
            makeQuestion(factID: "b"),
            makeQuestion(factID: "c")
        ])
        var iterations = 0
        while !session.isFinished {
            // Alternate between wrong and correct answers for variety.
            if iterations % 2 == 0 {
                try answerWrong(session: session)
            } else {
                try answerCorrect(session: session)
            }
            iterations += 1
            XCTAssertLessThan(iterations, 50, "Session should finish in bounded steps")
        }
        XCTAssertEqual(
            session.correctCount,
            session.totalQuestions,
            "correctCount must equal totalQuestions when session finishes"
        )
    }
}
