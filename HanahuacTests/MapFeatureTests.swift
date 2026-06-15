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

    func testRiverExposesSourceAndMouthAsLineEndpoints() {
        let river = makeRiver(id: "r", sLat: 1, sLon: 2, mLat: 3, mLon: 4)
        let ends = river.lineEndpoints
        XCTAssertNotNil(ends)
        XCTAssertEqual(ends?.start.latitude, 1)
        XCTAssertEqual(ends?.start.longitude, 2)
        XCTAssertEqual(ends?.end.latitude, 3)
        XCTAssertEqual(ends?.end.longitude, 4)
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
        XCTAssertNil(sea.lineEndpoints)
    }

    func testMountainPinUsesJSONLatLon() {
        let m = MountainRange(id: "m", name: "M", nameFr: nil, nameDe: nil, nameEs: nil,
                              continent: "X", lat: 28, lon: 84, highestPeak: "P", elevationMetres: 8000)
        XCTAssertEqual(m.pinCoordinate.latitude, 28)
        XCTAssertEqual(m.pinCoordinate.longitude, 84)
        XCTAssertNil(m.lineEndpoints)
    }

    // MARK: - Catalog

    func testCatalogReturnsFeaturesForEveryCategory() {
        for category in [CardCategory.country, .river, .mountain, .sea] {
            let features = MapFeatureCatalog.features(for: category)
            XCTAssertFalse(features.isEmpty, "Catalog should return features for \(category)")
        }
    }
}
