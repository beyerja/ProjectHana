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
    var correctLabel: String {
        options.first(where: \.isCorrect)?.label ?? ""
    }
}

enum MCQAnswerState: Equatable {
    case unanswered
    case correct(chosenID: UUID)
    case incorrect(chosenID: UUID, correctID: UUID)
}

@Observable
final class MultipleChoiceSession {
    private(set) var questions: [MCQQuestion]
    /// The number of distinct questions in the session, fixed at init (before shuffle).
    let totalQuestions: Int
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: MCQAnswerState = .unanswered
    private(set) var isFinished = false

    /// Total number of `advance()` calls made (includes retries for wrong answers).
    private var attemptCount = 0

    var current: MCQQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var reviewedCount: Int {
        attemptCount
    }

    var nextDueDate: Date? {
        questions.map(\.card.nextReviewDate).min()
    }

    init(questions: [MCQQuestion]) {
        totalQuestions = questions.count
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
        let quality = if case .correct = answerState { 4 } else { 1 }
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

    static func countryCapitalQuestions(
        cards: [ReviewCard],
        countries: [Country],
        locale: AppLocale = .en
    ) -> [MCQQuestion] {
        cards.compactMap { card in
            guard let country = countries.first(where: { $0.id == card.factID }) else { return nil }
            let distractors = countries
                .filter { $0.continent == country.continent && $0.id != country.id }
                .shuffled()
                .prefix(3)
                .map { MCQOption(label: $0.localizedCapital(for: locale), isCorrect: false) }
            guard distractors.count == 3 else { return nil }
            let options = ([MCQOption(label: country.localizedCapital(for: locale), isCorrect: true)] + distractors)
                .shuffled()
            let promptTemplate = L10n.string("quiz.prompt.capital_of", locale: locale)
            return MCQQuestion(
                card: card,
                prompt: String(format: promptTemplate, country.localizedName(for: locale)),
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
        categoryLabel _: String,
        locale: AppLocale = .en,
        factLocalizedName: ((T, AppLocale) -> String)? = nil
    ) -> [MCQQuestion] {
        // All canonical English continent names for distractor selection
        let allContinentsEnglish = ["Africa", "Asia", "Europe", "North America", "Oceania", "South America"]
        return cards.compactMap { card in
            guard let fact = facts.first(where: { factID($0) == card.factID }) else { return nil }
            let correctEnglish = factContinent(fact)
            let distractorEnglish = allContinentsEnglish.filter { $0 != correctEnglish }.shuffled().prefix(3)
            guard distractorEnglish.count == 3 else { return nil }
            let correctLabel = localizedContinent(correctEnglish, locale: locale)
            let options = ([MCQOption(label: correctLabel, isCorrect: true)] +
                distractorEnglish.map { MCQOption(label: localizedContinent($0, locale: locale), isCorrect: false) })
                .shuffled()
            let displayName = factLocalizedName?(fact, locale) ?? factName(fact)
            let promptTemplate = L10n.string("quiz.prompt.continent_of", locale: locale)
            return MCQQuestion(
                card: card,
                prompt: String(format: promptTemplate, displayName),
                options: options
            )
        }
    }

    static func seaIdentificationQuestions(
        cards: [ReviewCard],
        seas: [Sea],
        locale: AppLocale = .en
    ) -> [MCQQuestion] {
        cards.compactMap { card in
            guard let sea = seas.first(where: { $0.id == card.factID }) else { return nil }
            let distractors = seas.filter { $0.id != sea.id }.shuffled().prefix(3)
            guard distractors.count == 3 else { return nil }
            let options = ([MCQOption(label: sea.localizedName(for: locale), isCorrect: true)] +
                distractors.map { MCQOption(label: $0.localizedName(for: locale), isCorrect: false) }).shuffled()
            let region = approximateRegion(lat: sea.lat, lon: sea.lon, locale: locale)
            let promptTemplate = L10n.string("quiz.prompt.sea_location", locale: locale)
            return MCQQuestion(
                card: card,
                prompt: String(format: promptTemplate, region),
                options: options
            )
        }
    }

    // MARK: – Private helpers

    private static func approximateRegion(lat: Double, lon: Double, locale: AppLocale) -> String {
        let ns = L10n.string(lat >= 0 ? "quiz.region.north" : "quiz.region.south", locale: locale)
        let ew = L10n.string(lon >= 0 ? "quiz.region.east" : "quiz.region.west", locale: locale)
        return "\(Int(abs(lat)))°\(ns), \(Int(abs(lon)))°\(ew)"
    }

    /// Map an English continent name to its localized string.
    private static func localizedContinent(_ english: String, locale: AppLocale) -> String {
        let key: String
        switch english {
        case "Africa": key = "continent.africa"
        case "Asia": key = "continent.asia"
        case "Europe": key = "continent.europe"
        case "North America": key = "continent.north_america"
        case "Oceania": key = "continent.oceania"
        case "South America": key = "continent.south_america"
        default: return english
        }
        return L10n.string(key, locale: locale)
    }
}
