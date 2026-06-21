import MapKit
import SwiftUI
import XCTest
@testable import Hanahuac

final class MapQuizRegionHelperTests: XCTestCase {
    private func makeCountry(id: String, lat: Double, lon: Double) -> Country {
        Country(
            id: id,
            name: id,
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            capital: "Cap",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            continent: "EU",
            lat: lat,
            lon: lon
        )
    }

    /// Produce a spread of 15 countries around Europe for testing.
    private func makeCountries() -> [Country] {
        [
            makeCountry(id: "c0", lat: 48, lon: 14), // correct country
            makeCountry(id: "c1", lat: 52, lon: 13),
            makeCountry(id: "c2", lat: 46, lon: 8),
            makeCountry(id: "c3", lat: 47, lon: 20),
            makeCountry(id: "c4", lat: 51, lon: 4),
            makeCountry(id: "c5", lat: 43, lon: 12),
            makeCountry(id: "c6", lat: 55, lon: 9),
            makeCountry(id: "c7", lat: 60, lon: 25),
            makeCountry(id: "c8", lat: 41, lon: 20),
            makeCountry(id: "c9", lat: 50, lon: 30),
            makeCountry(id: "c10", lat: 38, lon: -8),
            makeCountry(id: "c11", lat: 35, lon: 14),
            makeCountry(id: "c12", lat: 42, lon: -3),
            makeCountry(id: "c13", lat: 64, lon: 26),
            makeCountry(id: "c14", lat: 44, lon: 26)
        ]
    }

    func testReturnsAtLeastTenAnnotationCountries() {
        let countries = makeCountries()
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
        // 1 correct + 10 nearest = 11 total (or fewer if allCountries is small)
        let expected = min(11, countries.count)
        XCTAssertEqual(
            result.features.count,
            expected,
            "Should return correct + 10 nearest neighbours"
        )
    }

    func testCorrectCountryIsIncluded() {
        let countries = makeCountries()
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
        XCTAssertTrue(
            result.features.contains { $0.id == correct.id },
            "Correct country must always be included in annotations"
        )
    }

    func testRegionVariesBetweenQuestions() {
        let countries = makeCountries()
        let correct = countries[0]
        // Jitter is preserved (just clamped), so across runs the center should move.
        var centers = Set<String>()
        for _ in 0 ..< 30 {
            let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
            let c = result.region.center
            centers.insert("\(Int(c.latitude * 100)):\(Int(c.longitude * 100))")
        }
        XCTAssertGreaterThan(centers.count, 1, "Region center should vary between questions (clamped jitter)")
    }

    func testWorksWithFewerThanTenNeighbours() {
        // Only 4 countries total — should return all of them without crashing.
        let countries = (0 ..< 4).map { makeCountry(id: "x\($0)", lat: Double($0), lon: Double($0)) }
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
        XCTAssertEqual(result.features.count, countries.count)
    }

    // MARK: - Region containment & clamped jitter

    /// Assert every pin lies inside the banner-free, aspect-corrected visible rect.
    private func assertAllPinsVisible(
        _ pins: [(Double, Double)],
        region: MKCoordinateRegion,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let rect = QuizRegionMath.visibleContentRect(for: region)
        // Compare longitude in screen-equivalent units (latitude compression) so a
        // wide spread at high latitude is judged the way it actually renders.
        let cosLat = max(0.2, cos(region.center.latitude * .pi / 180))
        for (lat, lon) in pins {
            XCTAssertGreaterThanOrEqual(lat, rect.minLat - 1e-6, "pin lat below rect", file: file, line: line)
            XCTAssertLessThanOrEqual(lat, rect.maxLat + 1e-6, "pin lat above rect", file: file, line: line)
            let lonScreen = lon * cosLat
            let minLonScreen = rect.minLon * cosLat
            let maxLonScreen = rect.maxLon * cosLat
            XCTAssertGreaterThanOrEqual(lonScreen, minLonScreen - 1e-6, "pin lon left of rect", file: file, line: line)
            XCTAssertLessThanOrEqual(lonScreen, maxLonScreen + 1e-6, "pin lon right of rect", file: file, line: line)
        }
    }

    func testAllPinsVisibleForRepresentativeEuropeanSpread() {
        let countries = makeCountries()
        let pins = countries.map { ($0.lat, $0.lon) }
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        assertAllPinsVisible(pins, region: region)
    }

    func testAllPinsVisibleUnderMaxJitterOnEveryAxis() {
        let countries = makeCountries()
        let pins = countries.map { ($0.lat, $0.lon) }
        // Drive jitter to its corners on both axes; clamping must keep pins visible.
        for latF in [-1.0, 0.0, 1.0] {
            for lonF in [-1.0, 0.0, 1.0] {
                let region = QuizRegionMath.region(
                    fittingPins: pins,
                    jitter: .fixed(latFraction: latF, lonFraction: lonF)
                )
                assertAllPinsVisible(pins, region: region)
            }
        }
    }

    func testAllPinsVisibleForWideHorizontalSpreadOnPortrait() {
        // A very wide east-west spread is the classic portrait-clipping case.
        let pins: [(Double, Double)] = [
            (40, -100), (42, -60), (38, -20), (41, 10), (39, 40), (43, 80), (40, 120)
        ]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        assertAllPinsVisible(pins, region: region)
    }

    func testAllPinsVisibleForWideSpreadAtHighLatitude() {
        // High latitude → strong longitude compression; must still fit horizontally.
        let pins: [(Double, Double)] = [
            (62, -40), (64, -10), (66, 20), (63, 50), (65, 90)
        ]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .fixed(latFraction: 1, lonFraction: -1))
        assertAllPinsVisible(pins, region: region)
    }

    func testRegionCenterDerivedFromBoundingBoxNotCorrectFeature() {
        // Correct feature is at an extreme corner; un-jittered center must be the
        // bounding-box center, not the correct feature's coordinate.
        let pins: [(Double, Double)] = [(0, 0), (0, 40), (40, 0), (40, 40)]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        XCTAssertEqual(region.center.latitude, 20, accuracy: 1e-6)
        XCTAssertEqual(region.center.longitude, 20, accuracy: 1e-6)
    }

    func testSinglePinProducesSaneSpan() {
        let pins: [(Double, Double)] = [(48, 14)]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .random)
        XCTAssertGreaterThan(region.span.latitudeDelta, 0)
        XCTAssertGreaterThan(region.span.longitudeDelta, 0)
        assertAllPinsVisible(pins, region: region)
    }

    func testCoincidentPinsProduceSaneSpan() {
        let pins: [(Double, Double)] = Array(repeating: (10, 10), count: 8)
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .random)
        XCTAssertGreaterThanOrEqual(region.span.latitudeDelta, QuizRegionMath.minSpanDegrees - 1e-6)
        assertAllPinsVisible(pins, region: region)
    }

    func testFullAnnotationRegionContainsAllPinsOverManyDraws() {
        let countries = makeCountries()
        let correct = countries[0]
        for _ in 0 ..< 200 {
            let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
            let pins = result.features.map { ($0.quizLat, $0.quizLon) }
            assertAllPinsVisible(pins, region: result.region)
        }
    }

    // MARK: - Camera bounds confine framing to the candidate-pin region

    // Regression: river/mountain/sea quizzes mis-centered because the `Map` framed
    // the union of its content — the full-course river `linePath` polylines and the
    // large sea/mountain `borderRings` polygons that extend FAR beyond the
    // candidate-pin bounding box — instead of the seeded candidate-pin region,
    // pushing every pin off-screen. Country worked because its borders are small and
    // local. The fix caps the camera via `MapCameraBounds` derived purely from the
    // candidate-pin region. These tests assert the cap is tight enough to exclude the
    // overlay extent while still framing every candidate pin.

    /// The framed span of `region` in metres, recomputed independently here exactly the
    /// way `QuizRegionMath.cameraDistance(for:)` does (latitude uncompressed, longitude
    /// scaled by cos(latitude)), so the test would fail if the cap were loosened to the
    /// overlay scale.
    private func framedSpanMeters(of region: MKCoordinateRegion) -> Double {
        let cosLat = max(0.2, cos(region.center.latitude * .pi / 180))
        let latMeters = region.span.latitudeDelta * QuizRegionMath.metersPerDegreeLatitude
        let lonMeters = region.span.longitudeDelta * cosLat * QuizRegionMath.metersPerDegreeLatitude
        return max(latMeters, lonMeters)
    }

    func testCameraDistanceCapStaysAtCandidatePinScaleNotOverlayScale() {
        // A handful of tightly-clustered candidate pins (e.g. nearby seas) whose large
        // overlay polygons/lines would otherwise span tens of degrees.
        let pins: [(Double, Double)] = [(35, 18), (37, 20), (34, 22), (36, 16), (33, 19)]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        // `cameraDistance` is the value that feeds the bounds' `maximumDistance` cap.
        let cap = QuizRegionMath.cameraDistance(for: region) * QuizRegionMath.cameraDistanceHeadroom

        // The cap must equal the framed candidate-pin span (times headroom) — i.e. stay
        // at the pin scale, never zoom out beyond it.
        XCTAssertLessThanOrEqual(
            cap,
            framedSpanMeters(of: region) * QuizRegionMath.cameraDistanceHeadroom + 1.0,
            "Camera cap must frame the candidate-pin span, not zoom out further"
        )

        // A full-course river / large sea polygon would span tens of degrees of latitude.
        // The cap must be far below that, so overlay extent can never re-frame the camera.
        let overlayExtentMeters = 60 * QuizRegionMath.metersPerDegreeLatitude
        XCTAssertLessThan(
            cap,
            overlayExtentMeters,
            "Camera cap must exclude the large overlay (river course / sea polygon) extent"
        )
    }

    func testCameraDistanceFramesEveryCandidatePin() {
        // The cap must still be large enough to show the whole candidate-pin region,
        // so no pin is clipped by an over-tight camera.
        let countries = makeCountries()
        let pins = countries.map { ($0.lat, $0.lon) }
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        let distance = QuizRegionMath.cameraDistance(for: region)

        XCTAssertGreaterThanOrEqual(
            distance + 1.0,
            framedSpanMeters(of: region),
            "Camera distance must cover the full framed span so no pin is clipped"
        )
    }

    func testCameraBoundsCenterRegionIsBoundingBoxNotCorrectPin() {
        // Correct pin sits at a corner; the camera-bounds centre region must be the
        // bounding-box-derived region, not biased toward the answer pin (no hint leak).
        let pins: [(Double, Double)] = [(0, 0), (0, 40), (40, 0), (40, 40)]
        let region = QuizRegionMath.region(fittingPins: pins, jitter: .none)
        XCTAssertEqual(region.center.latitude, 20, accuracy: 1e-6, "centre is bounding box, not a corner pin")
        XCTAssertEqual(region.center.longitude, 20, accuracy: 1e-6, "centre is bounding box, not a corner pin")
        // The bounds are derived from this same region, so the camera is constrained
        // around the bounding-box centre — never the answer pin's coordinate — and the
        // distance cap is finite (positive), pinning the camera to the region scale.
        _ = QuizRegionMath.cameraBounds(for: region)
        XCTAssertGreaterThan(
            QuizRegionMath.cameraDistance(for: region),
            0,
            "bounds must cap zoom-out to a finite region scale"
        )
    }

    // MARK: - Generic pin-in-polygon tests

    /// Verifies that every country with border data gets a computed pin coordinate that
    /// lies strictly inside its mainland polygon (largest ring). This test covers all
    /// countries generically — no per-country hardcoding required.
    func testAllCountryPinsAreInsideTheirMainlandBorderPolygon() {
        let borders = CountryBorderLoader.shared
        let provider = CountryPinCoordinateProvider(borders: borders)
        let geoData = GeographyDataLoader.load()

        // Only test countries that have border data; others fall back to raw lat/lon.
        let countriesWithBorders = geoData.countries.filter { borders[$0.id] != nil }
        XCTAssertFalse(
            countriesWithBorders.isEmpty,
            "Expected at least some countries to have border data"
        )

        var failures: [String] = []
        for country in countriesWithBorders {
            guard let rings = borders[country.id],
                  let mainland = rings.max(by: { $0.count < $1.count }) else { continue }
            let coord = provider.coordinate(for: country)
            let inside = PoleLabelCalculator.pointInPolygon(
                lon: coord.longitude, lat: coord.latitude, ring: mainland
            )
            if !inside {
                failures.append("\(country.id) (lat=\(coord.latitude), lon=\(coord.longitude))")
            }
        }

        XCTAssertTrue(
            failures.isEmpty,
            "These country pins are outside their mainland border polygon: \(failures.joined(separator: ", "))"
        )
    }
}
