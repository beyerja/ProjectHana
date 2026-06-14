import XCTest
@testable import Hanahuac

final class LocalizedGeoNameTests: XCTestCase {

    // MARK: - Country

    func testCountry_allLocales_returnCorrectName() {
        let country = Country(
            id: "de",
            name: "Germany",
            nameFr: "Allemagne",
            nameDe: "Deutschland",
            nameEs: "Alemania",
            capital: "Berlin",
            capitalFr: "Berlin",
            capitalDe: "Berlin",
            capitalEs: "Berlín",
            continent: "Europe",
            lat: 51,
            lon: 10
        )

        XCTAssertEqual(country.localizedName(for: .en), "Germany")
        XCTAssertEqual(country.localizedName(for: .fr), "Allemagne")
        XCTAssertEqual(country.localizedName(for: .de), "Deutschland")
        XCTAssertEqual(country.localizedName(for: .esMX), "Alemania")
    }

    func testCountry_missingFrenchName_fallsBackToEnglish() {
        let country = Country(
            id: "xx",
            name: "Testland",
            nameFr: nil,
            nameDe: "Testland DE",
            nameEs: "Testland ES",
            capital: "Testburg",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )

        XCTAssertEqual(country.localizedName(for: .fr), "Testland",
                       "Missing nameFr should fall back to English name")
    }

    func testCountry_missingGermanName_fallsBackToEnglish() {
        let country = Country(
            id: "xx",
            name: "Testland",
            nameFr: "Testland FR",
            nameDe: nil,
            nameEs: nil,
            capital: "Testburg",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )

        XCTAssertEqual(country.localizedName(for: .de), "Testland",
                       "Missing nameDe should fall back to English name")
    }

    func testCountry_missingSpanishName_fallsBackToEnglish() {
        let country = Country(
            id: "xx",
            name: "Testland",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            capital: "Testburg",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )

        XCTAssertEqual(country.localizedName(for: .esMX), "Testland",
                       "Missing nameEs should fall back to English name")
    }

    func testCountry_localizedCapital() {
        let country = Country(
            id: "fr",
            name: "France",
            nameFr: "France",
            nameDe: "Frankreich",
            nameEs: "Francia",
            capital: "Paris",
            capitalFr: "Paris",
            capitalDe: "Paris",
            capitalEs: "París",
            continent: "Europe",
            lat: 46,
            lon: 2
        )

        XCTAssertEqual(country.localizedCapital(for: .en), "Paris")
        XCTAssertEqual(country.localizedCapital(for: .fr), "Paris")
        XCTAssertEqual(country.localizedCapital(for: .de), "Paris")
        XCTAssertEqual(country.localizedCapital(for: .esMX), "París")
    }

    // MARK: - River

    func testRiver_allLocales_returnCorrectName() {
        let river = River(
            id: "rhine",
            name: "Rhine",
            nameFr: "Rhin",
            nameDe: "Rhein",
            nameEs: "Rin",
            continent: "Europe",
            sourceLat: 46.8, sourceLon: 9.2,
            mouthLat: 51.9, mouthLon: 4.0
        )

        XCTAssertEqual(river.localizedName(for: .en), "Rhine")
        XCTAssertEqual(river.localizedName(for: .fr), "Rhin")
        XCTAssertEqual(river.localizedName(for: .de), "Rhein")
        XCTAssertEqual(river.localizedName(for: .esMX), "Rin")
    }

    func testRiver_missingTranslation_fallsBackToEnglish() {
        let river = River(
            id: "test",
            name: "TestRiver",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            continent: "Asia",
            sourceLat: 0, sourceLon: 0,
            mouthLat: 1, mouthLon: 1
        )

        XCTAssertEqual(river.localizedName(for: .fr), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .de), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .esMX), "TestRiver")
    }

    // MARK: - MountainRange

    func testMountainRange_allLocales_returnCorrectName() {
        let range = MountainRange(
            id: "alps",
            name: "Alps",
            nameFr: "Alpes",
            nameDe: "Alpen",
            nameEs: "Alpes",
            continent: "Europe",
            lat: 46.5,
            lon: 8.0,
            highestPeak: "Mont Blanc",
            elevationMetres: 4808
        )

        XCTAssertEqual(range.localizedName(for: .en), "Alps")
        XCTAssertEqual(range.localizedName(for: .fr), "Alpes")
        XCTAssertEqual(range.localizedName(for: .de), "Alpen")
        XCTAssertEqual(range.localizedName(for: .esMX), "Alpes")
    }

    func testMountainRange_missingTranslation_fallsBackToEnglish() {
        let range = MountainRange(
            id: "test",
            name: "TestRange",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            continent: "Asia",
            lat: 0, lon: 0,
            highestPeak: "TestPeak",
            elevationMetres: 1000
        )

        XCTAssertEqual(range.localizedName(for: .fr), "TestRange")
        XCTAssertEqual(range.localizedName(for: .de), "TestRange")
        XCTAssertEqual(range.localizedName(for: .esMX), "TestRange")
    }

    // MARK: - Sea

    func testSea_allLocales_returnCorrectName() {
        let sea = Sea(
            id: "mediterranean",
            name: "Mediterranean Sea",
            nameFr: "Mer Méditerranée",
            nameDe: "Mittelmeer",
            nameEs: "Mar Mediterráneo",
            lat: 35.0,
            lon: 18.0
        )

        XCTAssertEqual(sea.localizedName(for: .en), "Mediterranean Sea")
        XCTAssertEqual(sea.localizedName(for: .fr), "Mer Méditerranée")
        XCTAssertEqual(sea.localizedName(for: .de), "Mittelmeer")
        XCTAssertEqual(sea.localizedName(for: .esMX), "Mar Mediterráneo")
    }

    func testSea_missingTranslation_fallsBackToEnglish() {
        let sea = Sea(
            id: "test",
            name: "TestSea",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            lat: 0,
            lon: 0
        )

        XCTAssertEqual(sea.localizedName(for: .fr), "TestSea")
        XCTAssertEqual(sea.localizedName(for: .de), "TestSea")
        XCTAssertEqual(sea.localizedName(for: .esMX), "TestSea")
    }
}
