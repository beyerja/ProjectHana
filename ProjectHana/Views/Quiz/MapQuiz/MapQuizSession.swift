import Foundation
import MapKit

enum AnswerState: Equatable {
    case unanswered
    case correct(id: String)
    case incorrect(tappedID: String, correctID: String)
}

@Observable
final class MapQuizSession {
    private(set) var cards: [ReviewCard]
    let allCountries: [Country]

    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: AnswerState = .unanswered
    private(set) var isFinished = false
    private(set) var annotationCountries: [Country] = []
    private(set) var mapRegion: MKCoordinateRegion = MKCoordinateRegion()

    var currentCard: ReviewCard? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }
    var currentCountry: Country? {
        guard let card = currentCard else { return nil }
        return allCountries.first { $0.id == card.factID }
    }
    var reviewedCount: Int { min(currentIndex, cards.count) }
    var nextDueDate: Date? { cards.compactMap { $0.nextReviewDate }.min() }

    init(cards: [ReviewCard], allCountries: [Country]) {
        self.cards = cards.shuffled()
        self.allCountries = allCountries
        refreshAnnotations()
    }

    func handleTap(countryID: String) {
        guard answerState == .unanswered, let correct = currentCountry else { return }
        if countryID == correct.id {
            answerState = .correct(id: countryID)
            correctCount += 1
        } else {
            answerState = .incorrect(tappedID: countryID, correctID: correct.id)
        }
    }

    func advance() {
        guard let card = currentCard else { return }
        let quality: Int
        switch answerState {
        case .correct:   quality = 4
        default:         quality = 1
        }
        let result = SM2Scheduler.schedule(card: card, quality: quality)
        SM2Scheduler.apply(result, to: card, quality: quality)
        StreakTracker.recordReview()

        currentIndex += 1
        if currentIndex >= cards.count {
            isFinished = true
        } else {
            answerState = .unanswered
            refreshAnnotations()
        }
    }

    // MARK: – Private

    private func refreshAnnotations() {
        guard let correct = currentCountry else { return }
        let result = makeQuizAnnotations(correct: correct, allCountries: allCountries)
        annotationCountries = result.countries
        mapRegion = result.region
    }
}
