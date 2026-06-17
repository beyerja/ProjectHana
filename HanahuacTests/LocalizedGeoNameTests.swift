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
            nameKo: "독일",
            nameNah: nil,
            capital: "Berlin",
            capitalFr: "Berlin",
            capitalDe: "Berlin",
            capitalEs: "Berlín",
            capitalKo: "베를린",
            capitalNah: nil,
            continent: "Europe",
            lat: 51,
            lon: 10
        )

        XCTAssertEqual(country.localizedName(for: .en), "Germany")
        XCTAssertEqual(country.localizedName(for: .fr), "Allemagne")
        XCTAssertEqual(country.localizedName(for: .de), "Deutschland")
        XCTAssertEqual(country.localizedName(for: .esMX), "Alemania")
        XCTAssertEqual(country.localizedName(for: .ko), "독일")
    }

    func testCountry_missingFrenchName_fallsBackToEnglish() {
        let country = makeCountry(name: "Testland", nameDe: "Testland DE", nameEs: "Testland ES")

        XCTAssertEqual(
            country.localizedName(for: .fr),
            "Testland",
            "Missing nameFr should fall back to English name"
        )
    }

    func testCountry_missingGermanName_fallsBackToEnglish() {
        let country = makeCountry(name: "Testland", nameFr: "Testland FR")

        XCTAssertEqual(
            country.localizedName(for: .de),
            "Testland",
            "Missing nameDe should fall back to English name"
        )
    }

    func testCountry_missingSpanishName_fallsBackToEnglish() {
        let country = makeCountry(name: "Testland")

        XCTAssertEqual(
            country.localizedName(for: .esMX),
            "Testland",
            "Missing nameEs should fall back to English name"
        )
    }

    /// Korean/Nahuatl name present → used directly.
    func testCountry_koAndNah_useTheirOwnName() {
        let country = makeCountry(name: "Testland", nameEs: "Tierra de Prueba", nameKo: "테스트랜드", nameNah: "Tlahtōllān")

        XCTAssertEqual(country.localizedName(for: .ko), "테스트랜드")
        XCTAssertEqual(country.localizedName(for: .nah), "Tlahtōllān")
    }

    /// Korean/Nahuatl name missing but Spanish present → falls back to Mexican Spanish, not English.
    func testCountry_koAndNah_fallBackToSpanishBeforeEnglish() {
        let country = makeCountry(name: "Testland", nameEs: "Tierra de Prueba")

        XCTAssertEqual(country.localizedName(for: .ko), "Tierra de Prueba")
        XCTAssertEqual(country.localizedName(for: .nah), "Tierra de Prueba")
    }

    /// Korean/Nahuatl and Spanish both missing → falls back to English.
    func testCountry_koAndNah_fallBackToEnglishWhenSpanishAlsoMissing() {
        let country = makeCountry(name: "Testland")

        XCTAssertEqual(country.localizedName(for: .ko), "Testland")
        XCTAssertEqual(country.localizedName(for: .nah), "Testland")
    }

    func testCountry_localizedCapital_koAndNahFallBackThroughSpanish() {
        // capitalKo present → used; capitalNah missing but capitalEs present → Spanish.
        let country = Country(
            id: "fr",
            name: "France",
            nameFr: "France",
            nameDe: "Frankreich",
            nameEs: "Francia",
            nameKo: "프랑스",
            nameNah: nil,
            capital: "Paris",
            capitalFr: "Paris",
            capitalDe: "Paris",
            capitalEs: "París",
            capitalKo: "파리",
            capitalNah: nil,
            continent: "Europe",
            lat: 46,
            lon: 2
        )

        XCTAssertEqual(country.localizedCapital(for: .en), "Paris")
        XCTAssertEqual(country.localizedCapital(for: .esMX), "París")
        XCTAssertEqual(country.localizedCapital(for: .ko), "파리")
        XCTAssertEqual(country.localizedCapital(for: .nah), "París", "Missing capitalNah → Mexican Spanish")
    }

    // MARK: - River

    func testRiver_allLocales_returnCorrectName() {
        let river = River(
            id: "rhine",
            name: "Rhine",
            nameFr: "Rhin",
            nameDe: "Rhein",
            nameEs: "Rin",
            nameKo: "라인강",
            nameNah: nil,
            continent: "Europe",
            sourceLat: 46.8, sourceLon: 9.2,
            mouthLat: 51.9, mouthLon: 4.0
        )

        XCTAssertEqual(river.localizedName(for: .en), "Rhine")
        XCTAssertEqual(river.localizedName(for: .fr), "Rhin")
        XCTAssertEqual(river.localizedName(for: .de), "Rhein")
        XCTAssertEqual(river.localizedName(for: .esMX), "Rin")
        XCTAssertEqual(river.localizedName(for: .ko), "라인강")
        XCTAssertEqual(river.localizedName(for: .nah), "Rin", "Missing nameNah → Mexican Spanish")
    }

    func testRiver_missingTranslation_fallsBackThroughChain() {
        let river = River(
            id: "test",
            name: "TestRiver",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            nameKo: nil,
            nameNah: nil,
            continent: "Asia",
            sourceLat: 0, sourceLon: 0,
            mouthLat: 1, mouthLon: 1
        )

        XCTAssertEqual(river.localizedName(for: .fr), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .de), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .esMX), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .ko), "TestRiver")
        XCTAssertEqual(river.localizedName(for: .nah), "TestRiver")
    }

    // MARK: - MountainRange

    func testMountainRange_allLocales_returnCorrectName() {
        let range = MountainRange(
            id: "alps",
            name: "Alps",
            nameFr: "Alpes",
            nameDe: "Alpen",
            nameEs: "Alpes",
            nameKo: "알프스산맥",
            nameNah: nil,
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
        XCTAssertEqual(range.localizedName(for: .ko), "알프스산맥")
        XCTAssertEqual(range.localizedName(for: .nah), "Alpes", "Missing nameNah → Mexican Spanish")
    }

    func testMountainRange_missingTranslation_fallsBackThroughChain() {
        let range = MountainRange(
            id: "test",
            name: "TestRange",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            nameKo: nil,
            nameNah: nil,
            continent: "Asia",
            lat: 0, lon: 0,
            highestPeak: "TestPeak",
            elevationMetres: 1000
        )

        XCTAssertEqual(range.localizedName(for: .fr), "TestRange")
        XCTAssertEqual(range.localizedName(for: .esMX), "TestRange")
        XCTAssertEqual(range.localizedName(for: .ko), "TestRange")
        XCTAssertEqual(range.localizedName(for: .nah), "TestRange")
    }

    // MARK: - Sea

    func testSea_allLocales_returnCorrectName() {
        let sea = Sea(
            id: "mediterranean",
            name: "Mediterranean Sea",
            nameFr: "Mer Méditerranée",
            nameDe: "Mittelmeer",
            nameEs: "Mar Mediterráneo",
            nameKo: "지중해",
            nameNah: nil,
            lat: 35.0,
            lon: 18.0
        )

        XCTAssertEqual(sea.localizedName(for: .en), "Mediterranean Sea")
        XCTAssertEqual(sea.localizedName(for: .fr), "Mer Méditerranée")
        XCTAssertEqual(sea.localizedName(for: .de), "Mittelmeer")
        XCTAssertEqual(sea.localizedName(for: .esMX), "Mar Mediterráneo")
        XCTAssertEqual(sea.localizedName(for: .ko), "지중해")
        XCTAssertEqual(sea.localizedName(for: .nah), "Mar Mediterráneo", "Missing nameNah → Mexican Spanish")
    }

    func testSea_missingTranslation_fallsBackThroughChain() {
        let sea = Sea(
            id: "test",
            name: "TestSea",
            nameFr: nil,
            nameDe: nil,
            nameEs: nil,
            nameKo: nil,
            nameNah: nil,
            lat: 0,
            lon: 0
        )

        XCTAssertEqual(sea.localizedName(for: .fr), "TestSea")
        XCTAssertEqual(sea.localizedName(for: .esMX), "TestSea")
        XCTAssertEqual(sea.localizedName(for: .ko), "TestSea")
        XCTAssertEqual(sea.localizedName(for: .nah), "TestSea")
    }

    // MARK: - Helpers

    private func makeCountry(
        name: String,
        nameFr: String? = nil,
        nameDe: String? = nil,
        nameEs: String? = nil,
        nameKo: String? = nil,
        nameNah: String? = nil
    ) -> Country {
        Country(
            id: "xx",
            name: name,
            nameFr: nameFr,
            nameDe: nameDe,
            nameEs: nameEs,
            nameKo: nameKo,
            nameNah: nameNah,
            capital: "Testburg",
            capitalFr: nil,
            capitalDe: nil,
            capitalEs: nil,
            capitalKo: nil,
            capitalNah: nil,
            continent: "Europe",
            lat: 0,
            lon: 0
        )
    }
}
