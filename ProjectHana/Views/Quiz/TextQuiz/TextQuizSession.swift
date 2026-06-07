import Foundation

enum TextAnswerState: Equatable {
    case unanswered
    case correct
    case incorrect(correctAnswer: String)
}

struct TextQuestion {
    let card: ReviewCard
    let prompt: String
    let correctAnswer: String
}

@Observable
final class TextQuizSession {
    let questions: [TextQuestion]
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: TextAnswerState = .unanswered
    private(set) var isFinished = false

    var current: TextQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }
    var reviewedCount: Int { min(currentIndex, questions.count) }
    var nextDueDate: Date? { questions.map(\.card.nextReviewDate).min() }

    init(questions: [TextQuestion]) {
        self.questions = questions.shuffled()
    }

    func checkAnswer(_ input: String) {
        guard answerState == .unanswered, let q = current else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare(q.correctAnswer) == .orderedSame {
            answerState = .correct
            correctCount += 1
        } else {
            answerState = .incorrect(correctAnswer: q.correctAnswer)
        }
    }

    func advance() {
        guard let q = current else { return }
        let quality: Int = (answerState == .correct) ? 4 : 1
        let result = SM2Scheduler.schedule(card: q.card, quality: quality)
        SM2Scheduler.apply(result, to: q.card, quality: quality)
        currentIndex += 1
        isFinished = currentIndex >= questions.count
        if !isFinished { answerState = .unanswered }
    }

    // MARK: – Factory methods

    static func capitalQuestions(cards: [ReviewCard], countries: [Country]) -> [TextQuestion] {
        cards.compactMap { card in
            guard let c = countries.first(where: { $0.id == card.factID }) else { return nil }
            return TextQuestion(card: card, prompt: "What is the capital of \(c.name)?", correctAnswer: c.capital)
        }
    }

    static func reverseCapitalQuestions(cards: [ReviewCard], countries: [Country]) -> [TextQuestion] {
        cards.compactMap { card in
            guard let c = countries.first(where: { $0.id == card.factID }) else { return nil }
            return TextQuestion(card: card, prompt: "Which country has \(c.capital) as its capital?", correctAnswer: c.name)
        }
    }
}
