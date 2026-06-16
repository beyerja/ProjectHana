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
    /// Fallback accepted answer in English (for bilingual validation).
    let fallbackAnswer: String?

    init(card: ReviewCard, prompt: String, correctAnswer: String, fallbackAnswer: String? = nil) {
        self.card = card
        self.prompt = prompt
        self.correctAnswer = correctAnswer
        self.fallbackAnswer = fallbackAnswer
    }
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

    var reviewedCount: Int {
        min(currentIndex, questions.count)
    }

    var nextDueDate: Date? {
        questions.map(\.card.nextReviewDate).min()
    }

    init(questions: [TextQuestion]) {
        self.questions = questions.shuffled()
    }

    func checkAnswer(_ input: String) {
        guard answerState == .unanswered, let q = current else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchesPrimary = trimmed.caseInsensitiveCompare(q.correctAnswer) == .orderedSame
        let matchesFallback = q.fallbackAnswer.map {
            trimmed.caseInsensitiveCompare($0) == .orderedSame
        } ?? false
        if matchesPrimary || matchesFallback {
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
        StreakTracker.recordReview()
        currentIndex += 1
        isFinished = currentIndex >= questions.count
        if !isFinished { answerState = .unanswered }
    }

    // MARK: – Factory methods

    static func capitalQuestions(
        cards: [ReviewCard],
        countries: [Country],
        locale: AppLocale = .en
    ) -> [TextQuestion] {
        cards.compactMap { card in
            guard let c = countries.first(where: { $0.id == card.factID }) else { return nil }
            let promptTemplate = L10n.string("quiz.prompt.capital_of", locale: locale)
            let localizedCapital = c.localizedCapital(for: locale)
            let fallback = locale == .en ? nil : c.capital
            return TextQuestion(
                card: card,
                prompt: String(format: promptTemplate, c.localizedName(for: locale)),
                correctAnswer: localizedCapital,
                fallbackAnswer: fallback
            )
        }
    }

    static func reverseCapitalQuestions(
        cards: [ReviewCard],
        countries: [Country],
        locale: AppLocale = .en
    ) -> [TextQuestion] {
        cards.compactMap { card in
            guard let c = countries.first(where: { $0.id == card.factID }) else { return nil }
            let promptTemplate = L10n.string("quiz.prompt.country_of_capital", locale: locale)
            let localizedName = c.localizedName(for: locale)
            let fallback = locale == .en ? nil : c.name
            return TextQuestion(
                card: card,
                prompt: String(format: promptTemplate, c.localizedCapital(for: locale)),
                correctAnswer: localizedName,
                fallbackAnswer: fallback
            )
        }
    }
}
