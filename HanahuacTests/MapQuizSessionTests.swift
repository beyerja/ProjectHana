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
}
