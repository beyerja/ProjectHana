import Foundation

struct MCQOption: Identifiable {
    let id = UUID()
    let label: String
    let isCorrect: Bool
}

struct MCQQuestion {
    let card: ReviewCard
    let prompt: String
    let options: [MCQOption]
    var correctLabel: String { options.first(where: \.isCorrect)?.label ?? "" }
}

enum MCQAnswerState: Equatable {
    case unanswered
    case correct(chosenID: UUID)
    case incorrect(chosenID: UUID, correctID: UUID)
}

@Observable
final class MultipleChoiceSession {
    let questions: [MCQQuestion]
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: MCQAnswerState = .unanswered
    private(set) var isFinished = false

    var current: MCQQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }
    var reviewedCount: Int { min(currentIndex, questions.count) }
    var nextDueDate: Date? { questions.map(\.card.nextReviewDate).min() }

    init(questions: [MCQQuestion]) {
        self.questions = questions.shuffled()
    }

    func select(optionID: UUID) {
        guard answerState == .unanswered, let q = current else { return }
        guard let chosen = q.options.first(where: { $0.id == optionID }) else { return }
        let correctOpt = q.options.first(where: \.isCorrect)!
        if chosen.isCorrect {
            answerState = .correct(chosenID: optionID)
            correctCount += 1
        } else {
            answerState = .incorrect(chosenID: optionID, correctID: correctOpt.id)
        }
    }

    func advance() {
        guard let q = current else { return }
        let quality: Int
        if case .correct = answerState { quality = 4 } else { quality = 1 }
        let result = SM2Scheduler.schedule(card: q.card, quality: quality)
        SM2Scheduler.apply(result, to: q.card, quality: quality)
        currentIndex += 1
        isFinished = currentIndex >= questions.count
        if !isFinished { answerState = .unanswered }
    }

    // MARK: – Factory methods

    static func countryCapitalQuestions(cards: [ReviewCard], countries: [Country]) -> [MCQQuestion] {
        cards.compactMap { card in
            guard let country = countries.first(where: { $0.id == card.factID }) else { return nil }
            let distractors = countries
                .filter { $0.continent == country.continent && $0.id != country.id }
                .shuffled()
                .prefix(3)
                .map { MCQOption(label: $0.capital, isCorrect: false) }
            guard distractors.count == 3 else { return nil }
            let options = ([MCQOption(label: country.capital, isCorrect: true)] + distractors).shuffled()
            return MCQQuestion(
                card: card,
                prompt: "What is the capital of \(country.name)?",
                options: options
            )
        }
    }

    static func continentQuestions<T: Identifiable & Hashable>(
        cards: [ReviewCard],
        facts: [T],
        factID: (T) -> String,
        factName: (T) -> String,
        factContinent: (T) -> String,
        categoryLabel: String
    ) -> [MCQQuestion] {
        let allContinents = ["Africa", "Asia", "Europe", "North America", "Oceania", "South America"]
        return cards.compactMap { card in
            guard let fact = facts.first(where: { factID($0) == card.factID }) else { return nil }
            let correct = factContinent(fact)
            let distractors = allContinents.filter { $0 != correct }.shuffled().prefix(3)
            guard distractors.count == 3 else { return nil }
            let options = ([MCQOption(label: correct, isCorrect: true)] +
                           distractors.map { MCQOption(label: $0, isCorrect: false) }).shuffled()
            return MCQQuestion(
                card: card,
                prompt: "On which continent is \(factName(fact)) located?",
                options: options
            )
        }
    }

    static func seaIdentificationQuestions(cards: [ReviewCard], seas: [Sea]) -> [MCQQuestion] {
        cards.compactMap { card in
            guard let sea = seas.first(where: { $0.id == card.factID }) else { return nil }
            let distractors = seas.filter { $0.id != sea.id }.shuffled().prefix(3)
            guard distractors.count == 3 else { return nil }
            let options = ([MCQOption(label: sea.name, isCorrect: true)] +
                           distractors.map { MCQOption(label: $0.name, isCorrect: false) }).shuffled()
            let region = approximateRegion(lat: sea.lat, lon: sea.lon)
            return MCQQuestion(
                card: card,
                prompt: "Which body of water is located at approximately \(region)?",
                options: options
            )
        }
    }

    private static func approximateRegion(lat: Double, lon: Double) -> String {
        let ns = lat >= 0 ? "N" : "S"
        let ew = lon >= 0 ? "E" : "W"
        return "\(Int(abs(lat)))°\(ns), \(Int(abs(lon)))°\(ew)"
    }
}
