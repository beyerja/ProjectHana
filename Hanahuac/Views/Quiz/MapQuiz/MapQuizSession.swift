import Foundation
import MapKit
import SwiftUI

enum AnswerState: Equatable {
    case unanswered
    case correct(id: String)
    case incorrect(tappedID: String, correctID: String)
}

extension AnswerState {
    /// Semi-transparent fill color for a country polygon given the current answer state.
    func polygonFillColor(for countryID: String) -> Color {
        switch self {
        case .unanswered:
            return .clear
        case .correct(let id):
            return countryID == id ? Theme.Palette.correct.opacity(0.35) : .clear
        case .incorrect(let tappedID, let correctID):
            if countryID == tappedID  { return Theme.Palette.wrong.opacity(0.35) }
            if countryID == correctID { return Theme.Palette.correct.opacity(0.35) }
            return .clear
        }
    }
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

        // Dual penalty: also penalise the incorrectly-tapped card if it's in the deck.
        if case .incorrect(let tappedID, _) = answerState, tappedID != card.factID {
            if let tappedCard = cards.first(where: { $0.factID == tappedID }) {
                let tappedResult = SM2Scheduler.schedule(card: tappedCard, quality: 1)
                SM2Scheduler.apply(tappedResult, to: tappedCard, quality: 1)
            }
        }

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
