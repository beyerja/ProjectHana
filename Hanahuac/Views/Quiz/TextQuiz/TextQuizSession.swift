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
    private(set) var questions: [TextQuestion]
    /// The number of distinct questions in the session, fixed at init (before shuffle).
    let totalQuestions: Int
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: TextAnswerState = .unanswered
    private(set) var isFinished = false

    /// Total number of `advance()` calls made (includes retries for wrong answers).
    private var attemptCount = 0

    var current: TextQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var reviewedCount: Int {
        attemptCount
    }

    var nextDueDate: Date? {
        questions.map(\.card.nextReviewDate).min()
    }

    init(questions: [TextQuestion]) {
        totalQuestions = questions.count
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
        // The streak belongs to the reviewed card's language, keeping streaks per-language.
        StreakTracker.recordReview(language: q.card.language)

        attemptCount += 1

        if case .incorrect = answerState {
            // Wrong answer: reinsert question later in the queue so the user sees it again.
            questions.remove(at: currentIndex)
            let insertAt = Int.random(in: max(1, currentIndex) ..< max(2, questions.count + 1))
            questions.insert(q, at: min(insertAt, questions.count))
            // currentIndex stays — the next question slides into the same position.
        } else {
            currentIndex += 1
        }

        // Safety: if the queue is exhausted before correctCount reaches totalQuestions
        // (e.g. a degenerate empty-question edge case), finish to avoid an infinite loop.
        if currentIndex >= questions.count {
            isFinished = true
            return
        }

        if correctCount == totalQuestions {
            isFinished = true
        } else {
            answerState = .unanswered
        }
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

    /// Questions for the map-pin "Name that feature" quiz: each due card is paired
    /// with its `MappableFeature` (any category). The feature itself is shown on the
    /// map by the view, so the prompt is just the localized "Name this …"
    /// instruction. The accepted answer is the feature's localized name, with the
    /// English name accepted as a fallback for non-English locales — mirroring the
    /// capital-quiz matching semantics so Korean/Nahuatl (resolved via the model's
    /// ko→es→en / nah→es→en chain) and English answers both validate.
    static func nameFeatureQuestions(
        cards: [ReviewCard],
        features: [any MappableFeature],
        locale: AppLocale = .en
    ) -> [TextQuestion] {
        let byID = Dictionary(features.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return cards.compactMap { card in
            guard let feature = byID[card.factID] else { return nil }
            let localizedName = feature.localizedName(for: locale)
            // `localizedName(for: .en)` returns the bundled English `name` for every
            // category, so it is the English fallback without needing `name` on the
            // protocol.
            let englishName = feature.localizedName(for: .en)
            let fallback = (locale == .en || englishName == localizedName) ? nil : englishName
            return TextQuestion(
                card: card,
                prompt: L10n.string("name_feature.prompt", locale: locale),
                correctAnswer: localizedName,
                fallbackAnswer: fallback
            )
        }
    }
}
