import XCTest
import MapKit
import CoreLocation
@testable import ProjectHana

final class MapQuizRegionHelperTests: XCTestCase {

    private func makeCountry(id: String, lat: Double, lon: Double) -> Country {
        Country(id: id, name: id, nameFr: nil, nameDe: nil, nameEs: nil,
                capital: "Cap", capitalFr: nil, capitalDe: nil, capitalEs: nil,
                continent: "EU", lat: lat, lon: lon)
    }

    // Produce a spread of 15 countries around Europe for testing.
    private func makeCountries() -> [Country] {
        [
            makeCountry(id: "c0",  lat: 48, lon: 14),   // correct country
            makeCountry(id: "c1",  lat: 52, lon: 13),
            makeCountry(id: "c2",  lat: 46, lon: 8),
            makeCountry(id: "c3",  lat: 47, lon: 20),
            makeCountry(id: "c4",  lat: 51, lon: 4),
            makeCountry(id: "c5",  lat: 43, lon: 12),
            makeCountry(id: "c6",  lat: 55, lon: 9),
            makeCountry(id: "c7",  lat: 60, lon: 25),
            makeCountry(id: "c8",  lat: 41, lon: 20),
            makeCountry(id: "c9",  lat: 50, lon: 30),
            makeCountry(id: "c10", lat: 38, lon: -8),
            makeCountry(id: "c11", lat: 35, lon: 14),
            makeCountry(id: "c12", lat: 42, lon: -3),
            makeCountry(id: "c13", lat: 64, lon: 26),
            makeCountry(id: "c14", lat: 44, lon: 26),
        ]
    }

    func testReturnsAtLeastTenAnnotationCountries() {
        let countries = makeCountries()
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allCountries: countries)
        // 1 correct + 10 nearest = 11 total (or fewer if allCountries is small)
        let expected = min(11, countries.count)
        XCTAssertEqual(result.countries.count, expected,
                       "Should return correct + 10 nearest neighbours")
    }

    func testCorrectCountryIsIncluded() {
        let countries = makeCountries()
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allCountries: countries)
        XCTAssertTrue(result.countries.contains(correct),
                      "Correct country must always be included in annotations")
    }

    func testCenterIsOffsetFromCorrectCountry() {
        let countries = makeCountries()
        let correct = countries[0]
        // Run several times due to randomness; at least some runs must produce an offset.
        var anyOffset = false
        for _ in 0..<20 {
            let result = makeQuizAnnotations(correct: correct, allCountries: countries)
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
        let result = makeQuizAnnotations(correct: correct, allCountries: countries)
        XCTAssertGreaterThanOrEqual(result.region.span.latitudeDelta, 20,
                                    "Latitude span must be at least 20°")
        XCTAssertGreaterThanOrEqual(result.region.span.longitudeDelta, 20,
                                    "Longitude span must be at least 20°")
    }

    func testWorksWithFewerThanTenNeighbours() {
        // Only 4 countries total — should return all of them without crashing.
        let countries = (0..<4).map { makeCountry(id: "x\($0)", lat: Double($0), lon: Double($0)) }
        let correct = countries[0]
        let result = makeQuizAnnotations(correct: correct, allCountries: countries)
        XCTAssertEqual(result.countries.count, countries.count)
    }

    // MARK: - Pin Coordinate Tests

    /// Returns true if (lon, lat) is inside the given polygon using the ray-casting algorithm.
    private func pointInPolygon(lon: Double, lat: Double, polygon: [CLLocationCoordinate2D]) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }
        var inside = false
        var j = n - 1
        for i in 0..<n {
            let xi = polygon[i].longitude, yi = polygon[i].latitude
            let xj = polygon[j].longitude, yj = polygon[j].latitude
            if ((yi > lat) != (yj > lat)) &&
               (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    func testNorwayPinIsInsideMainlandBorder() {
        // Norway (NO) mainland ring is the largest ring in country-borders.json.
        let borders = CountryBorderLoader.shared
        guard let rings = borders["NO"] else {
            XCTFail("No border data found for Norway (NO)")
            return
        }
        // Pick the largest ring as the mainland polygon.
        let mainland = rings.max(by: { $0.count < $1.count }) ?? []
        XCTAssertFalse(mainland.isEmpty, "Norway mainland ring must not be empty")

        let countries = GeographyDataLoader.load().countries
        guard let norway = countries.first(where: { $0.id == "NO" }) else {
            XCTFail("Norway not found in countries.json")
            return
        }

        let isInside = pointInPolygon(lon: norway.lon, lat: norway.lat, polygon: mainland)
        XCTAssertTrue(isInside,
            "Norway pin (lat=\(norway.lat), lon=\(norway.lon)) must be inside the mainland border polygon")
    }

    func testSwedenPinIsInsideMainlandBorder() {
        let borders = CountryBorderLoader.shared
        guard let rings = borders["SE"] else {
            XCTFail("No border data found for Sweden (SE)")
            return
        }
        let mainland = rings.max(by: { $0.count < $1.count }) ?? []
        XCTAssertFalse(mainland.isEmpty, "Sweden mainland ring must not be empty")

        let countries = GeographyDataLoader.load().countries
        guard let sweden = countries.first(where: { $0.id == "SE" }) else {
            XCTFail("Sweden not found in countries.json")
            return
        }

        let isInside = pointInPolygon(lon: sweden.lon, lat: sweden.lat, polygon: mainland)
        XCTAssertTrue(isInside,
            "Sweden pin (lat=\(sweden.lat), lon=\(sweden.lon)) must be inside the mainland border polygon")
    }
}
