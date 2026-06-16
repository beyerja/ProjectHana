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
    let questions: [MCQQuestion]
    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: MCQAnswerState = .unanswered
    private(set) var isFinished = false

    var current: MCQQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var reviewedCount: Int {
        min(currentIndex, questions.count)
    }

    var nextDueDate: Date? {
        questions.map(\.card.nextReviewDate).min()
    }

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
        let quality = if case .correct = answerState { 4 } else { 1 }
        let result = SM2Scheduler.schedule(card: q.card, quality: quality)
        SM2Scheduler.apply(result, to: q.card, quality: quality)
        StreakTracker.recordReview()
        currentIndex += 1
        isFinished = currentIndex >= questions.count
        if !isFinished { answerState = .unanswered }
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
            let region = approximateRegion(lat: sea.lat, lon: sea.lon)
            return MCQQuestion(
                card: card,
                prompt: "Which body of water is located at approximately \(region)?",
                options: options
            )
        }
    }

    // MARK: – Private helpers

    private static func approximateRegion(lat: Double, lon: Double) -> String {
        let ns = lat >= 0 ? "N" : "S"
        let ew = lon >= 0 ? "E" : "W"
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
