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
            return countryID == id ? .green.opacity(0.35) : .clear
        case .incorrect(let tappedID, let correctID):
            if countryID == tappedID  { return .red.opacity(0.35) }
            if countryID == correctID { return .green.opacity(0.35) }
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
        let continent = allCountries.filter {
            $0.continent == correct.continent && $0.id != correct.id
        }
        let nearest = continent
            .sorted { distance($0, from: correct) < distance($1, from: correct) }
            .prefix(5)
        annotationCountries = ([correct] + nearest).shuffled()
        mapRegion = region(for: annotationCountries)
    }

    private func distance(_ a: Country, from b: Country) -> Double {
        let dLat = a.lat - b.lat
        let dLon = a.lon - b.lon
        return sqrt(dLat * dLat + dLon * dLon)
    }

    private func region(for countries: [Country]) -> MKCoordinateRegion {
        guard !countries.isEmpty else { return MKCoordinateRegion() }
        let lats = countries.map(\.lat)
        let lons = countries.map(\.lon)
        let centerLat = (lats.min()! + lats.max()!) / 2
        let centerLon = (lons.min()! + lons.max()!) / 2
        let spanLat = max(12, (lats.max()! - lats.min()!) * 1.6)
        let spanLon = max(12, (lons.max()! - lons.min()!) * 1.6)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
}
