import Foundation
import MapKit
import Observation

/// A learning session for new country cards that uses the map quiz interaction
/// and the same 3-consecutive-correct graduation mechanic as `LearningSession`.
///
/// - `recordCorrect()` / `recordWrong()` drive the streak; 3 in a row graduates a card.
/// - The existing `MapQuizSession` (used for due/Pending cards) is unchanged.
@Observable
final class MapLearningSession {
    static let activeSetSize = 10
    static let requiredStreak = 3

    // MARK: - Learning state

    private(set) var activeSet: [ReviewCard]
    private(set) var pendingPool: [ReviewCard]
    private(set) var currentIndex = 0
    private(set) var graduatedCount = 0
    private(set) var isFinished = false
    let totalNewCards: Int

    // MARK: - Map state

    let allCountries: [Country]
    private(set) var answerState: AnswerState = .unanswered
    private(set) var annotationCountries: [Country] = []
    private(set) var mapRegion: MKCoordinateRegion = MKCoordinateRegion()

    var current: ReviewCard? {
        activeSet.indices.contains(currentIndex) ? activeSet[currentIndex] : nil
    }

    var currentCountry: Country? {
        guard let card = current else { return nil }
        return allCountries.first { $0.id == card.factID }
    }

    // MARK: - Init

    init(newCards: [ReviewCard], allCountries: [Country]) {
        totalNewCards = newCards.count
        self.allCountries = allCountries

        let shuffled = newCards.shuffled()
        activeSet = Array(shuffled.prefix(MapLearningSession.activeSetSize))
        pendingPool = Array(shuffled.dropFirst(MapLearningSession.activeSetSize))

        refreshAnnotations()
    }

    // MARK: - Map interaction

    func handleTap(countryID: String) {
        guard answerState == .unanswered, currentCountry != nil else { return }
        guard let correct = currentCountry else { return }
        if countryID == correct.id {
            answerState = .correct(id: countryID)
        } else {
            answerState = .incorrect(tappedID: countryID, correctID: correct.id)
        }
    }

    // MARK: - Answer recording (called after the UI delay)

    func recordCorrect() {
        guard let card = current else { return }
        card.consecutiveCorrect += 1
        if card.consecutiveCorrect >= MapLearningSession.requiredStreak {
            graduate(card)
        } else {
            advance()
        }
        answerState = .unanswered
        if !isFinished { refreshAnnotations() }
    }

    func recordWrong() {
        guard let card = current else { return }
        card.consecutiveCorrect = 0
        // Reinsert later in the queue (same as LearningSession)
        activeSet.remove(at: currentIndex)
        let insertAt = Int.random(in: max(1, currentIndex)..<max(2, activeSet.count + 1))
        activeSet.insert(card, at: min(insertAt, activeSet.count))
        if currentIndex >= activeSet.count { currentIndex = 0 }
        answerState = .unanswered
        refreshAnnotations()
    }

    // MARK: - Private

    private func graduate(_ card: ReviewCard) {
        card.hasGraduated = true
        let result = SM2Scheduler.schedule(card: card, quality: 4)
        SM2Scheduler.apply(result, to: card, quality: 4)
        graduatedCount += 1

        activeSet.remove(at: currentIndex)

        if let next = pendingPool.first {
            pendingPool.removeFirst()
            activeSet.append(next)
        }

        if activeSet.isEmpty {
            isFinished = true
        } else if currentIndex >= activeSet.count {
            currentIndex = 0
        }
    }

    private func advance() {
        currentIndex = (currentIndex + 1) % max(1, activeSet.count)
    }

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
