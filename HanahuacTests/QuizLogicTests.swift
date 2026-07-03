import SwiftData
import XCTest
@testable import Hanahuac

@MainActor
final class QuizLogicTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(factID: String = "fr", category: CardCategory = .country) -> ReviewCard {
        let card = ReviewCard(factID: factID, category: category)
        container.mainContext.insert(card)
        return card
    }

    // MARK: – TextQuizSession: case-insensitive matching

    func testTextAnswer_caseInsensitive() {
        let card = makeCard()
        let session = TextQuizSession(questions: [TextQuestion(card: card, prompt: "?", correctAnswer: "Paris")])
        session.checkAnswer("paris")
        XCTAssertEqual(session.answerState, .correct)
    }

    func testTextAnswer_whitespaceTrimmingCorrect() {
        let card = makeCard()
        let session = TextQuizSession(questions: [TextQuestion(card: card, prompt: "?", correctAnswer: "Berlin")])
        session.checkAnswer("  Berlin  ")
        XCTAssertEqual(session.answerState, .correct)
    }

    func testTextAnswer_whitespaceTrimmingIncorrect() {
        let card = makeCard()
        let session = TextQuizSession(questions: [TextQuestion(card: card, prompt: "?", correctAnswer: "Berlin")])
        session.checkAnswer("   ")
        if case let .incorrect(answer) = session.answerState {
            XCTAssertEqual(answer, "Berlin")
        } else {
            XCTFail("Expected incorrect answer state")
        }
    }

    func testTextAnswer_mixedCaseAndWhitespace() {
        let card = makeCard()
        let session = TextQuizSession(questions: [TextQuestion(card: card, prompt: "?", correctAnswer: "New Delhi")])
        session.checkAnswer("  new delhi  ")
        XCTAssertEqual(session.answerState, .correct)
    }

    func testTextAnswer_wrongAnswer() {
        let card = makeCard()
        let session = TextQuizSession(questions: [TextQuestion(card: card, prompt: "?", correctAnswer: "Paris")])
        session.checkAnswer("London")
        if case let .incorrect(answer) = session.answerState {
            XCTAssertEqual(answer, "Paris")
        } else {
            XCTFail("Expected incorrect state")
        }
    }

    // MARK: – MCQ: options validity

    func testMCQOptions_fourOptions() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        XCTAssertEqual(q.options.count, 4)
    }

    func testMCQOptions_exactlyOneCorrect() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        XCTAssertEqual(q.options.filter(\.isCorrect).count, 1)
    }

    func testMCQOptions_correctAnswerIsCapital() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Paris")
    }

    func testMCQOptions_noDuplicateLabels() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        let labels = q.options.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count, "Option labels must be unique")
    }

    func testMCQOptions_noDistractorEqualsCorrect() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        let distractors = q.options.filter { !$0.isCorrect }
        for d in distractors {
            XCTAssertNotEqual(d.label, "Paris", "Distractor must differ from correct answer")
        }
    }

    func testContinentQuestions_correctContinent() {
        let card = makeCard(factID: "rhine", category: .river)
        let questions = MultipleChoiceSession.continentQuestions(
            cards: [card], facts: sampleRivers(),
            factID: \.id, factName: \.name, factContinent: \.continent,
            categoryLabel: "river"
        )
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Europe")
    }

    func testContinentQuestions_fourDistinctOptions() {
        let card = makeCard(factID: "rhine", category: .river)
        let questions = MultipleChoiceSession.continentQuestions(
            cards: [card], facts: sampleRivers(),
            factID: \.id, factName: \.name, factContinent: \.continent,
            categoryLabel: "river"
        )
        guard let q = questions.first else { XCTFail("No questions generated")
            return
        }
        XCTAssertEqual(q.options.count, 4)
        XCTAssertEqual(Set(q.options.map(\.label)).count, 4)
    }

    // MARK: – MultipleChoiceSessionRetryTests

    /// Helper: make a minimal MCQQuestion with one correct and one incorrect option.
    private func makeMCQQuestion(factID: String) -> MCQQuestion {
        let card = makeCard(factID: factID)
        let correct = MCQOption(label: "Correct-\(factID)", isCorrect: true)
        let wrong = MCQOption(label: "Wrong-\(factID)", isCorrect: false)
        return MCQQuestion(card: card, prompt: "Q-\(factID)", options: [correct, wrong])
    }

    /// Select the wrong option on the current question and call advance().
    private func answerWrong(session: MultipleChoiceSession) throws {
        let q = try XCTUnwrap(session.current)
        let wrongOpt = try XCTUnwrap(q.options.first { !$0.isCorrect })
        session.select(optionID: wrongOpt.id)
        session.advance()
    }

    /// Select the correct option on the current question and call advance().
    private func answerCorrect(session: MultipleChoiceSession) throws {
        let q = try XCTUnwrap(session.current)
        let correctOpt = try XCTUnwrap(q.options.first(where: \.isCorrect))
        session.select(optionID: correctOpt.id)
        session.advance()
    }

    func testMCQRetry_wrongAnswerReinserts_sessionNotFinished() throws {
        let session = MultipleChoiceSession(questions: [makeMCQQuestion(factID: "a")])
        try answerWrong(session: session)
        XCTAssertFalse(session.isFinished, "Session must not be finished after one wrong answer")
        XCTAssertNotNil(session.current, "The reinserted question must be present as current")
    }

    func testMCQRetry_notFinishedAfterOneWrongAnswer() throws {
        let q1 = makeMCQQuestion(factID: "a")
        let q2 = makeMCQQuestion(factID: "b")
        let session = MultipleChoiceSession(questions: [q1, q2])
        // Answer the first current question incorrectly.
        try answerWrong(session: session)
        XCTAssertFalse(session.isFinished, "Session must not finish after a single wrong answer")
    }

    func testMCQRetry_finishesOnlyAfterAllCorrect() throws {
        let q1 = makeMCQQuestion(factID: "a")
        let q2 = makeMCQQuestion(factID: "b")
        let session = MultipleChoiceSession(questions: [q1, q2])
        // Drive the session until finished, always answering correctly.
        var iterations = 0
        while !session.isFinished {
            try answerCorrect(session: session)
            iterations += 1
            XCTAssertLessThan(iterations, 20, "Session should finish in a bounded number of steps")
        }
        XCTAssertTrue(session.isFinished, "Session must be finished after all correct")
        XCTAssertEqual(
            session.correctCount, session.totalQuestions,
            "correctCount must equal totalQuestions when session finishes"
        )
    }

    func testMCQRetry_reviewedCountCountsAttempts() throws {
        let session = MultipleChoiceSession(questions: [makeMCQQuestion(factID: "a")])
        let wrongAnswers = 3
        for _ in 0 ..< wrongAnswers {
            try answerWrong(session: session)
        }
        try answerCorrect(session: session)
        // N wrong + 1 correct = N+1 attempts total.
        XCTAssertEqual(
            session.reviewedCount, wrongAnswers + 1,
            "reviewedCount must equal total advance() calls (wrong + correct)"
        )
    }

    func testMCQRetry_correctCountEqualsTotalQuestionsOnFinish() throws {
        let q1 = makeMCQQuestion(factID: "a")
        let q2 = makeMCQQuestion(factID: "b")
        let q3 = makeMCQQuestion(factID: "c")
        let session = MultipleChoiceSession(questions: [q1, q2, q3])
        // Answer some wrong, all eventually correct, then verify correctCount.
        var iterations = 0
        while !session.isFinished {
            // Answer wrong on even iterations for variety, correct otherwise.
            if iterations % 2 == 0 {
                try answerWrong(session: session)
            } else {
                try answerCorrect(session: session)
            }
            iterations += 1
            XCTAssertLessThan(iterations, 50, "Session should finish in bounded steps")
        }
        XCTAssertEqual(
            session.correctCount, session.totalQuestions,
            "correctCount must equal totalQuestions when session finishes"
        )
    }

    // MARK: – Fixtures

    private func sampleCountries() -> [Country] {
        [
            Country(
                id: "fr",
                name: "France",
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Paris",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "Europe",
                lat: 46,
                lon: 2
            ),
            Country(
                id: "de",
                name: "Germany",
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Berlin",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "Europe",
                lat: 51,
                lon: 10
            ),
            Country(
                id: "es",
                name: "Spain",
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Madrid",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "Europe",
                lat: 40,
                lon: -4
            ),
            Country(
                id: "it",
                name: "Italy",
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Rome",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "Europe",
                lat: 42,
                lon: 12
            ),
            Country(
                id: "pt",
                name: "Portugal",
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Lisbon",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "Europe",
                lat: 39,
                lon: -8
            )
        ]
    }

    private func sampleRivers() -> [River] {
        [River(
            id: "rhine",
            name: "Rhine",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            continent: "Europe",
            sourceLat: 46.8,
            sourceLon: 9.2,
            mouthLat: 51.9,
            mouthLon: 4.0
        )]
    }
}
