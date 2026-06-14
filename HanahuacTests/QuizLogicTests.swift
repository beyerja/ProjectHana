import XCTest
import SwiftData
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
        if case .incorrect(let answer) = session.answerState {
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
        if case .incorrect(let answer) = session.answerState {
            XCTAssertEqual(answer, "Paris")
        } else {
            XCTFail("Expected incorrect state")
        }
    }

    // MARK: – MCQ: options validity

    func testMCQOptions_fourOptions() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertEqual(q.options.count, 4)
    }

    func testMCQOptions_exactlyOneCorrect() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertEqual(q.options.filter(\.isCorrect).count, 1)
    }

    func testMCQOptions_correctAnswerIsCapital() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Paris")
    }

    func testMCQOptions_noDuplicateLabels() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let labels = q.options.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count, "Option labels must be unique")
    }

    func testMCQOptions_noDistractorEqualsCorrect() {
        let card = makeCard(factID: "fr")
        let questions = MultipleChoiceSession.countryCapitalQuestions(cards: [card], countries: sampleCountries())
        guard let q = questions.first else { XCTFail("No questions generated"); return }
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
        guard let q = questions.first else { XCTFail("No questions generated"); return }
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
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertEqual(q.options.count, 4)
        XCTAssertEqual(Set(q.options.map(\.label)).count, 4)
    }

    // MARK: – Fixtures

    private func sampleCountries() -> [Country] {
        [
            Country(id: "fr", name: "France", nameFr: nil, nameDe: nil, nameEs: nil, capital: "Paris", capitalFr: nil, capitalDe: nil, capitalEs: nil, continent: "Europe", lat: 46, lon: 2),
            Country(id: "de", name: "Germany", nameFr: nil, nameDe: nil, nameEs: nil, capital: "Berlin", capitalFr: nil, capitalDe: nil, capitalEs: nil, continent: "Europe", lat: 51, lon: 10),
            Country(id: "es", name: "Spain", nameFr: nil, nameDe: nil, nameEs: nil, capital: "Madrid", capitalFr: nil, capitalDe: nil, capitalEs: nil, continent: "Europe", lat: 40, lon: -4),
            Country(id: "it", name: "Italy", nameFr: nil, nameDe: nil, nameEs: nil, capital: "Rome", capitalFr: nil, capitalDe: nil, capitalEs: nil, continent: "Europe", lat: 42, lon: 12),
            Country(id: "pt", name: "Portugal", nameFr: nil, nameDe: nil, nameEs: nil, capital: "Lisbon", capitalFr: nil, capitalDe: nil, capitalEs: nil, continent: "Europe", lat: 39, lon: -8),
        ]
    }

    private func sampleRivers() -> [River] {
        [River(id: "rhine", name: "Rhine", nameFr: nil, nameDe: nil, nameEs: nil, continent: "Europe",
               sourceLat: 46.8, sourceLon: 9.2, mouthLat: 51.9, mouthLon: 4.0)]
    }
}
