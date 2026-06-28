import Foundation
import MapKit
import SwiftUI

enum AnswerState: Equatable {
    case unanswered
    case correct(id: String)
    case incorrect(tappedID: String, correctID: String)
}

extension AnswerState {
    /// Semi-transparent fill color for a feature's polygon given the answer state.
    func polygonFillColor(for featureID: String) -> Color {
        switch self {
        case .unanswered:
            return .clear
        case let .correct(id):
            return featureID == id ? Theme.Palette.correct.opacity(0.35) : .clear
        case let .incorrect(tappedID, correctID):
            if featureID == tappedID { return Theme.Palette.wrong.opacity(0.35) }
            if featureID == correctID { return Theme.Palette.correct.opacity(0.35) }
            return .clear
        }
    }
}

@Observable
final class MapQuizSession {
    private(set) var cards: [ReviewCard]
    let allFeatures: [any MappableFeature]

    private(set) var currentIndex = 0
    private(set) var correctCount = 0
    private(set) var answerState: AnswerState = .unanswered
    private(set) var isFinished = false
    private(set) var annotationFeatures: [any MappableFeature] = []
    private(set) var mapRegion: MKCoordinateRegion = .init()

    /// The number of distinct cards in the session, fixed at init (before shuffle).
    private(set) var totalCards: Int

    /// Total number of `advance()` calls made (includes retries for wrong answers).
    private var attemptCount = 0

    var currentCard: ReviewCard? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var currentFeature: (any MappableFeature)? {
        guard let card = currentCard else { return nil }
        return allFeatures.first { $0.id == card.factID }
    }

    /// Total attempts made so far (advances, including retries).
    var reviewedCount: Int {
        attemptCount
    }

    var nextDueDate: Date? {
        cards.compactMap(\.nextReviewDate).min()
    }

    init(cards: [ReviewCard], allFeatures: [any MappableFeature]) {
        totalCards = cards.count
        self.cards = cards.shuffled()
        self.allFeatures = allFeatures
        refreshAnnotations()
    }

    func handleTap(featureID: String) {
        guard answerState == .unanswered, let correct = currentFeature else { return }
        if featureID == correct.id {
            answerState = .correct(id: featureID)
            correctCount += 1
        } else {
            answerState = .incorrect(tappedID: featureID, correctID: correct.id)
        }
    }

    func advance() {
        guard let card = currentCard else { return }
        let quality = switch answerState {
        case .correct: 4
        default: 1
        }
        let result = SM2Scheduler.schedule(card: card, quality: quality)
        SM2Scheduler.apply(result, to: card, quality: quality)

        // Dual penalty: also penalise the incorrectly-tapped card if it's in the deck.
        if case let .incorrect(tappedID, _) = answerState, tappedID != card.factID {
            if let tappedCard = cards.first(where: { $0.factID == tappedID }) {
                let tappedResult = SM2Scheduler.schedule(card: tappedCard, quality: 1)
                SM2Scheduler.apply(tappedResult, to: tappedCard, quality: 1)
            }
        }

        // The streak belongs to the reviewed card's language, keeping streaks per-language.
        StreakTracker.recordReview(language: card.language)

        attemptCount += 1

        if case .incorrect = answerState {
            // Wrong answer: reinsert card later in the queue so the user sees it again.
            cards.remove(at: currentIndex)
            let insertAt = Int.random(in: max(1, currentIndex) ..< max(2, cards.count + 1))
            cards.insert(card, at: min(insertAt, cards.count))
            // currentIndex stays — next card slides into the same position.
        } else {
            currentIndex += 1
        }

        if correctCount == totalCards {
            isFinished = true
        } else {
            answerState = .unanswered
            refreshAnnotations()
        }
    }

    // MARK: – Private

    private func refreshAnnotations() {
        guard let correct = currentFeature else { return }
        let result = makeQuizAnnotations(correct: correct, allFeatures: allFeatures)
        annotationFeatures = result.features
        mapRegion = result.region
    }
}
