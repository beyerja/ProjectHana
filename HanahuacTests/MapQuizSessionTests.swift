import MapKit
import SwiftData
import XCTest
@testable import Hanahuac

/// Tests that `MapQuizSession` and `MapLearningSession` each seed `mapRegion` with a
/// non-default, non-zero span immediately on construction — so the SwiftUI `Map` view
/// receives a real framing region before the first render rather than the zero-span
/// `.init()` default.
///
/// This covers AC1–AC3 (river / mountain / sea initial framing) and AC8 (countries)
/// at the session layer, without depending on the view hierarchy.
@MainActor
final class MapQuizSessionTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDownWithError() throws {
        container = nil
    }

    // MARK: - Helpers

    private func makeCard(factID: String, category: CardCategory = .country) -> ReviewCard {
        let card = ReviewCard(factID: factID, category: category)
        container.mainContext.insert(card)
        return card
    }

    private struct CountryCoord {
        let id: String
        let lat: Double
        let lon: Double
    }

    /// A minimal spread of Country features whose pin coordinates are just their raw lat/lon
    /// (no border data to load, so no shared-resource dependency).
    private func makeCountries() -> [Country] {
        let coords: [CountryCoord] = [
            CountryCoord(id: "c0", lat: 48, lon: 14),
            CountryCoord(id: "c1", lat: 52, lon: 13),
            CountryCoord(id: "c2", lat: 46, lon: 8),
            CountryCoord(id: "c3", lat: 47, lon: 20),
            CountryCoord(id: "c4", lat: 51, lon: 4),
            CountryCoord(id: "c5", lat: 43, lon: 12),
            CountryCoord(id: "c6", lat: 55, lon: 9),
            CountryCoord(id: "c7", lat: 60, lon: 25),
            CountryCoord(id: "c8", lat: 41, lon: 20),
            CountryCoord(id: "c9", lat: 50, lon: 30),
            CountryCoord(id: "c10", lat: 38, lon: -8),
            CountryCoord(id: "c11", lat: 35, lon: 14),
            CountryCoord(id: "c12", lat: 42, lon: -3),
            CountryCoord(id: "c13", lat: 64, lon: 26),
            CountryCoord(id: "c14", lat: 44, lon: 26)
        ]
        return coords.map { c in
            Country(
                id: c.id,
                name: c.id,
                nameFr: nil,
                nameDe: nil,
                nameEs: nil,
                capital: "Cap",
                capitalFr: nil,
                capitalDe: nil,
                capitalEs: nil,
                continent: "EU",
                lat: c.lat,
                lon: c.lon
            )
        }
    }

    /// Sea features whose pin coordinate is the explicit lat/lon from the model (no border-loader).
    private func makeSeas() -> [Sea] {
        [
            Sea(id: "s0", name: "S0", nameFr: nil, nameDe: nil, nameEs: nil, lat: 36, lon: 14),
            Sea(id: "s1", name: "S1", nameFr: nil, nameDe: nil, nameEs: nil, lat: 43, lon: 15),
            Sea(id: "s2", name: "S2", nameFr: nil, nameDe: nil, nameEs: nil, lat: 40, lon: 19),
            Sea(id: "s3", name: "S3", nameFr: nil, nameDe: nil, nameEs: nil, lat: 38, lon: 22),
            Sea(id: "s4", name: "S4", nameFr: nil, nameDe: nil, nameEs: nil, lat: 55, lon: 18),
            Sea(id: "s5", name: "S5", nameFr: nil, nameDe: nil, nameEs: nil, lat: 60, lon: 20),
            Sea(id: "s6", name: "S6", nameFr: nil, nameDe: nil, nameEs: nil, lat: 35, lon: -5),
            Sea(id: "s7", name: "S7", nameFr: nil, nameDe: nil, nameEs: nil, lat: 44, lon: 33),
            Sea(id: "s8", name: "S8", nameFr: nil, nameDe: nil, nameEs: nil, lat: 37, lon: 25),
            Sea(id: "s9", name: "S9", nameFr: nil, nameDe: nil, nameEs: nil, lat: 65, lon: 15),
            Sea(id: "s10", name: "S10", nameFr: nil, nameDe: nil, nameEs: nil, lat: 69, lon: 19),
            Sea(id: "s11", name: "S11", nameFr: nil, nameDe: nil, nameEs: nil, lat: 58, lon: 22)
        ]
    }

    /// MountainRange features whose pin coordinate is the explicit lat/lon from the model (no border-loader).
    private func makeMountainRanges() -> [MountainRange] {
        [
            MountainRange(
                id: "m0", name: "M0", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 46, lon: 9, highestPeak: "P0", elevationMetres: 4000
            ),
            MountainRange(
                id: "m1", name: "M1", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 43, lon: 0, highestPeak: "P1", elevationMetres: 3400
            ),
            MountainRange(
                id: "m2", name: "M2", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 42, lon: 24, highestPeak: "P2", elevationMetres: 2900
            ),
            MountainRange(
                id: "m3", name: "M3", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 44, lon: 43, highestPeak: "P3", elevationMetres: 5600
            ),
            MountainRange(
                id: "m4", name: "M4", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 47, lon: 13, highestPeak: "P4", elevationMetres: 3700
            ),
            MountainRange(
                id: "m5", name: "M5", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 63, lon: 9, highestPeak: "P5", elevationMetres: 2469
            ),
            MountainRange(
                id: "m6", name: "M6", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 65, lon: 17, highestPeak: "P6", elevationMetres: 2117
            ),
            MountainRange(
                id: "m7", name: "M7", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 41, lon: 20, highestPeak: "P7", elevationMetres: 2764
            ),
            MountainRange(
                id: "m8", name: "M8", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 45, lon: 26, highestPeak: "P8", elevationMetres: 2544
            ),
            MountainRange(
                id: "m9", name: "M9", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 50, lon: 19, highestPeak: "P9", elevationMetres: 1602
            ),
            MountainRange(
                id: "m10", name: "M10", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 43, lon: 12, highestPeak: "P10", elevationMetres: 2914
            ),
            MountainRange(
                id: "m11", name: "M11", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", lat: 37, lon: -3, highestPeak: "P11", elevationMetres: 3478
            )
        ]
    }

    /// River features whose pin coordinate is the source→mouth midpoint (no path-loader).
    private func makeRivers() -> [River] {
        [
            River(
                id: "r0", name: "R0", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 45, sourceLon: 8, mouthLat: 51, mouthLon: 4
            ),
            River(
                id: "r1", name: "R1", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 46, sourceLon: 9, mouthLat: 47, mouthLon: 6
            ),
            River(
                id: "r2", name: "R2", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 43, sourceLon: 12, mouthLat: 45, mouthLon: 13
            ),
            River(
                id: "r3", name: "R3", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 48, sourceLon: 14, mouthLat: 50, mouthLon: 15
            ),
            River(
                id: "r4", name: "R4", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 52, sourceLon: 13, mouthLat: 53, mouthLon: 14
            ),
            River(
                id: "r5", name: "R5", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 55, sourceLon: 9, mouthLat: 56, mouthLon: 10
            ),
            River(
                id: "r6", name: "R6", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 60, sourceLon: 25, mouthLat: 61, mouthLon: 26
            ),
            River(
                id: "r7", name: "R7", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 41, sourceLon: 20, mouthLat: 42, mouthLon: 21
            ),
            River(
                id: "r8", name: "R8", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 50, sourceLon: 30, mouthLat: 51, mouthLon: 31
            ),
            River(
                id: "r9", name: "R9", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 38, sourceLon: -8, mouthLat: 39, mouthLon: -7
            ),
            River(
                id: "r10", name: "R10", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 35, sourceLon: 14, mouthLat: 36, mouthLon: 15
            ),
            River(
                id: "r11", name: "R11", nameFr: nil, nameDe: nil, nameEs: nil,
                continent: "EU", sourceLat: 42, sourceLon: -3, mouthLat: 43, mouthLon: -2
            )
        ]
    }

    // MARK: - MapQuizSession: mapRegion seeded on init

    func testMapQuizSessionCountry_mapRegionHasNonZeroSpanOnInit() {
        let countries = makeCountries()
        let cards = countries.map { makeCard(factID: $0.id, category: .country) }
        let session = MapQuizSession(cards: cards, allFeatures: countries)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapQuizSession(country) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapQuizSession(country) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapQuizSessionRiver_mapRegionHasNonZeroSpanOnInit() {
        let rivers = makeRivers()
        let cards = rivers.map { makeCard(factID: $0.id, category: .river) }
        let session = MapQuizSession(cards: cards, allFeatures: rivers)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapQuizSession(river) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapQuizSession(river) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapQuizSessionSea_mapRegionHasNonZeroSpanOnInit() {
        let seas = makeSeas()
        let cards = seas.map { makeCard(factID: $0.id, category: .sea) }
        let session = MapQuizSession(cards: cards, allFeatures: seas)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapQuizSession(sea) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapQuizSession(sea) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapQuizSessionMountain_mapRegionHasNonZeroSpanOnInit() {
        let mountains = makeMountainRanges()
        let cards = mountains.map { makeCard(factID: $0.id, category: .mountain) }
        let session = MapQuizSession(cards: cards, allFeatures: mountains)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapQuizSession(mountain) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapQuizSession(mountain) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    // MARK: - MapQuizSession: retry mechanic

    /// Build a small 3-card country session for driving retry tests.
    private func makeRetrySession() -> MapQuizSession {
        let countries = [
            Country(
                id: "r_c0", name: "Alpha", nameFr: nil, nameDe: nil, nameEs: nil,
                capital: "A", capitalFr: nil, capitalDe: nil, capitalEs: nil,
                continent: "EU", lat: 48, lon: 14
            ),
            Country(
                id: "r_c1", name: "Beta", nameFr: nil, nameDe: nil, nameEs: nil,
                capital: "B", capitalFr: nil, capitalDe: nil, capitalEs: nil,
                continent: "EU", lat: 52, lon: 13
            ),
            Country(
                id: "r_c2", name: "Gamma", nameFr: nil, nameDe: nil, nameEs: nil,
                capital: "G", capitalFr: nil, capitalDe: nil, capitalEs: nil,
                continent: "EU", lat: 46, lon: 8
            )
        ]
        let cards = countries.map { makeCard(factID: $0.id, category: .country) }
        return MapQuizSession(cards: cards, allFeatures: countries)
    }

    /// Answer the current card correctly and advance.
    private func tapCorrect(_ session: MapQuizSession) {
        guard let id = session.currentCard?.factID else { return }
        session.handleTap(featureID: id)
        session.advance()
    }

    /// Answer the current card incorrectly (tap a placeholder ID) and advance.
    private func tapWrong(_ session: MapQuizSession) {
        session.handleTap(featureID: "__wrong__")
        session.advance()
    }

    func testRetry_wrongTapLeavesCardCountUnchanged() {
        let session = makeRetrySession()
        let countBefore = session.cards.count
        tapWrong(session)
        XCTAssertEqual(
            session.cards.count,
            countBefore,
            "A wrong tap must remove and reinsert the card (net-zero): cards.count must be unchanged"
        )
    }

    func testRetry_notFinishedAfterOneWrongAnswer() {
        let session = makeRetrySession()
        tapWrong(session)
        XCTAssertFalse(
            session.isFinished,
            "Session must not be finished after a single wrong answer"
        )
    }

    func testRetry_finishesWhenAllCardsAnsweredCorrectly() {
        let session = makeRetrySession()
        let total = session.totalCards
        var safetyLimit = total * 20
        while !session.isFinished, safetyLimit > 0 {
            safetyLimit -= 1
            switch session.answerState {
            case .unanswered:
                // Tap correct every time so session eventually finishes.
                guard let id = session.currentCard?.factID else { break }
                session.handleTap(featureID: id)
            default:
                session.advance()
            }
        }
        XCTAssertTrue(session.isFinished, "Session must be finished after all cards answered correctly")
        XCTAssertEqual(
            session.correctCount,
            total,
            "correctCount must equal totalCards when session finishes"
        )
    }

    func testRetry_reviewedCountIncludesWrongAttempts() {
        let session = makeRetrySession()
        // Tap wrong 2 times, then tap correct once — total 3 advances.
        tapWrong(session)
        tapWrong(session)
        tapCorrect(session)
        XCTAssertEqual(
            session.reviewedCount,
            3,
            "reviewedCount must count every advance(): 2 wrongs + 1 correct = 3"
        )
    }

    func testRetry_correctCountEqualsTotalCardsAtFinish() {
        let session = makeRetrySession()
        let total = session.totalCards
        var safetyLimit = total * 20
        while !session.isFinished, safetyLimit > 0 {
            safetyLimit -= 1
            switch session.answerState {
            case .unanswered:
                guard let id = session.currentCard?.factID else { break }
                session.handleTap(featureID: id)
            default:
                session.advance()
            }
        }
        XCTAssertEqual(
            session.correctCount,
            total,
            "correctCount must equal the original totalCards at session finish"
        )
    }

    // MARK: - MapLearningSession: mapRegion seeded on init

    func testMapLearningSessionCountry_mapRegionHasNonZeroSpanOnInit() {
        let countries = makeCountries()
        let cards = countries.map { makeCard(factID: $0.id, category: .country) }
        let session = MapLearningSession(newCards: cards, allFeatures: countries)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapLearningSession(country) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapLearningSession(country) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapLearningSessionRiver_mapRegionHasNonZeroSpanOnInit() {
        let rivers = makeRivers()
        let cards = rivers.map { makeCard(factID: $0.id, category: .river) }
        let session = MapLearningSession(newCards: cards, allFeatures: rivers)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapLearningSession(river) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapLearningSession(river) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapLearningSessionSea_mapRegionHasNonZeroSpanOnInit() {
        let seas = makeSeas()
        let cards = seas.map { makeCard(factID: $0.id, category: .sea) }
        let session = MapLearningSession(newCards: cards, allFeatures: seas)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapLearningSession(sea) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapLearningSession(sea) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }

    func testMapLearningSessionMountain_mapRegionHasNonZeroSpanOnInit() {
        let mountains = makeMountainRanges()
        let cards = mountains.map { makeCard(factID: $0.id, category: .mountain) }
        let session = MapLearningSession(newCards: cards, allFeatures: mountains)
        XCTAssertGreaterThan(
            session.mapRegion.span.latitudeDelta,
            0,
            "MapLearningSession(mountain) mapRegion.latitudeDelta must be > 0 immediately after init"
        )
        XCTAssertGreaterThan(
            session.mapRegion.span.longitudeDelta,
            0,
            "MapLearningSession(mountain) mapRegion.longitudeDelta must be > 0 immediately after init"
        )
    }
}
