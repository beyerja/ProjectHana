import MapKit
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

    func testCenterIsOffsetFromCorrectCountry() {
        let countries = makeCountries()
        let correct = countries[0]
        // Run several times due to randomness; at least some runs must produce an offset.
        var anyOffset = false
        for _ in 0 ..< 20 {
            let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
            let center = result.region.center
            if abs(center.latitude - correct.lat) > 0.001 || abs(center.longitude - correct.lon) > 0.001 {
                anyOffset = true
                break
            }
        }
        XCTAssertTrue(anyOffset, "Center should be offset from the correct country's coordinate in at least some runs")
    }

    func testSpanIsAtLeast20Degrees() {
        let countries = makeCountries()
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
        XCTAssertGreaterThanOrEqual(
            result.region.span.latitudeDelta,
            20,
            "Latitude span must be at least 20°"
        )
        XCTAssertGreaterThanOrEqual(
            result.region.span.longitudeDelta,
            20,
            "Longitude span must be at least 20°"
        )
    }

    func testWorksWithFewerThanTenNeighbours() {
        // Only 4 countries total — should return all of them without crashing.
        let countries = (0 ..< 4).map { makeCountry(id: "x\($0)", lat: Double($0), lon: Double($0)) }
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allFeatures: countries)
        XCTAssertEqual(result.features.count, countries.count)
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
