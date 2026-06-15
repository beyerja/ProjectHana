import XCTest
import SwiftData
import CoreLocation
@testable import Hanahuac

/// Tests for the generalized `MappableFeature` abstraction across the
/// rivers, mountains, and seas categories.
@MainActor
final class MapFeatureTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCard(factID: String, category: CardCategory) -> ReviewCard {
        let card = ReviewCard(factID: factID, category: category)
        container.mainContext.insert(card)
        return card
    }

    // MARK: - River geometry

    private func makeRiver(id: String, sLat: Double, sLon: Double, mLat: Double, mLon: Double) -> River {
        River(id: id, name: id, nameFr: nil, nameDe: nil, nameEs: nil, continent: "X",
              sourceLat: sLat, sourceLon: sLon, mouthLat: mLat, mouthLon: mLon)
    }

    func testRiverPinIsMidpointOfSourceAndMouth() {
        let river = makeRiver(id: "r", sLat: 0, sLon: 0, mLat: 10, mLon: 20)
        let pin = river.pinCoordinate
        XCTAssertEqual(pin.latitude, 5, accuracy: 1e-9)
        XCTAssertEqual(pin.longitude, 10, accuracy: 1e-9)
    }

    func testRiverWithoutPathDataFallsBackToStraightSourceMouthLine() {
        // An id with no entry in river-paths.json must fall back to a single
        // straight part running source → mouth (graceful degradation).
        let river = makeRiver(id: "no-such-river-xyz", sLat: 1, sLon: 2, mLat: 3, mLon: 4)
        let path = river.linePath
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.count, 1, "fallback is a single straight part")
        let part = try? XCTUnwrap(path?.first)
        XCTAssertEqual(part?.count, 2, "straight fallback has exactly the two endpoints")
        XCTAssertEqual(part?.first?.latitude, 1)
        XCTAssertEqual(part?.first?.longitude, 2)
        XCTAssertEqual(part?.last?.latitude, 3)
        XCTAssertEqual(part?.last?.longitude, 4)
    }

    func testRiverHasNoBorderRings() {
        let river = makeRiver(id: "r", sLat: 0, sLon: 0, mLat: 1, mLon: 1)
        XCTAssertNil(river.borderRings)
    }

    func testRiverSessionScoresCorrectAndIncorrect() {
        let r1 = makeRiver(id: "nile", sLat: 4, sLon: 31, mLat: 31, mLon: 31)
        let r2 = makeRiver(id: "amazon", sLat: -15, sLon: -71, mLat: 0, mLon: -49)
        let features: [any MappableFeature] = [r1, r2]
        let card = makeCard(factID: "nile", category: .river)
        let session = MapQuizSession(cards: [card], allFeatures: features)
        XCTAssertEqual(session.currentFeature?.id, "nile")
        session.handleTap(featureID: "amazon")  // wrong
        if case .incorrect(let tapped, let correct) = session.answerState {
            XCTAssertEqual(tapped, "amazon")
            XCTAssertEqual(correct, "nile")
        } else {
            XCTFail("Expected incorrect answer state")
        }
    }

    func testRiverLearningGraduatesAfterThreeCorrect() {
        let r = makeRiver(id: "nile", sLat: 4, sLon: 31, mLat: 31, mLon: 31)
        let card = makeCard(factID: "nile", category: .river)
        let session = MapLearningSession(newCards: [card], allFeatures: [r])
        session.handleTap(featureID: "nile"); session.recordCorrect()
        session.handleTap(featureID: "nile"); session.recordCorrect()
        XCTAssertFalse(card.hasGraduated)
        session.handleTap(featureID: "nile"); session.recordCorrect()
        XCTAssertTrue(card.hasGraduated)
    }

    // MARK: - Sea & Mountain conformance

    func testSeaPinUsesJSONLatLon() {
        let sea = Sea(id: "s", name: "S", nameFr: nil, nameDe: nil, nameEs: nil, lat: 12, lon: -34)
        XCTAssertEqual(sea.pinCoordinate.latitude, 12)
        XCTAssertEqual(sea.pinCoordinate.longitude, -34)
        XCTAssertNil(sea.linePath)
    }

    func testMountainPinUsesJSONLatLon() {
        let m = MountainRange(id: "m", name: "M", nameFr: nil, nameDe: nil, nameEs: nil,
                              continent: "X", lat: 28, lon: 84, highestPeak: "P", elevationMetres: 8000)
        XCTAssertEqual(m.pinCoordinate.latitude, 28)
        XCTAssertEqual(m.pinCoordinate.longitude, 84)
        XCTAssertNil(m.linePath)
    }

    // MARK: - Sea border data

    func testSeaBorderLoaderMatchesAllSeasByID() {
        let borders = SeaBorderLoader.shared
        let seas = GeographyDataLoader.load().seas
        XCTAssertFalse(seas.isEmpty)

        // Every loaded border id must correspond to a known sea id.
        let seaIDs = Set(seas.map(\.id))
        for id in borders.keys {
            XCTAssertTrue(seaIDs.contains(id), "Sea border id '\(id)' has no matching sea")
        }

        // All 20 seas should have a matched polygon (see story 003 spec).
        let unmatched = seas.filter { borders[$0.id] == nil }.map(\.id)
        XCTAssertTrue(unmatched.isEmpty, "Seas missing a border polygon: \(unmatched)")

        // Rings should be non-trivial polygons.
        for (id, rings) in borders {
            XCTAssertFalse(rings.isEmpty, "Sea '\(id)' has no rings")
            XCTAssertTrue(rings.allSatisfy { $0.count >= 4 }, "Sea '\(id)' has a degenerate ring")
        }
    }

    func testSeaBorderRingsExposedViaMappableFeature() {
        let borders = SeaBorderLoader.shared
        let seas = GeographyDataLoader.load().seas
        guard let withBorder = seas.first(where: { borders[$0.id] != nil }) else {
            return XCTFail("Expected at least one sea with a border polygon")
        }
        XCTAssertNotNil(withBorder.borderRings)
    }

    // MARK: - Mountain border data + pin-only fallback

    func testMountainBorderLoaderIDsAllMatchKnownMountains() {
        let borders = MountainBorderLoader.shared
        let mountains = GeographyDataLoader.load().mountains
        let mtnIDs = Set(mountains.map(\.id))
        XCTAssertFalse(borders.isEmpty, "Expected mountain border polygons to load")
        for id in borders.keys {
            XCTAssertTrue(mtnIDs.contains(id), "Mountain border id '\(id)' has no matching range")
        }
    }

    func testMountainPinOnlyFallbackForUnmatchedRange() {
        let borders = MountainBorderLoader.shared
        let mountains = GeographyDataLoader.load().mountains
        // At least one range is intentionally pin-only (e.g. East African Rift).
        let pinOnly = mountains.filter { borders[$0.id] == nil }
        XCTAssertFalse(pinOnly.isEmpty, "Expected at least one pin-only mountain range")
        // A pin-only range exposes nil rings but still has a valid pin coordinate
        // and functions in a session without crashing.
        let range = pinOnly[0]
        XCTAssertNil(range.borderRings)
        let card = makeCard(factID: range.id, category: .mountain)
        let session = MapQuizSession(cards: [card], allFeatures: [range])
        XCTAssertEqual(session.currentFeature?.id, range.id)
        session.handleTap(featureID: range.id)
        if case .correct = session.answerState {} else { XCTFail("Expected correct state") }
    }

    func testMountainWithPolygonExposesRings() {
        let borders = MountainBorderLoader.shared
        let mountains = GeographyDataLoader.load().mountains
        guard let withBorder = mountains.first(where: { borders[$0.id] != nil }) else {
            return XCTFail("Expected at least one mountain with a polygon")
        }
        XCTAssertNotNil(withBorder.borderRings)
    }

    // MARK: - Catalog

    func testCatalogReturnsFeaturesForEveryCategory() {
        for category in [CardCategory.country, .river, .mountain, .sea] {
            let features = MapFeatureCatalog.features(for: category)
            XCTAssertFalse(features.isEmpty, "Catalog should return features for \(category)")
        }
    }
}
