import XCTest
@testable import Hanahuac

final class GeographyDataLoaderTests: XCTestCase {
    private var data: GeographyData!

    override func setUpWithError() throws {
        data = GeographyDataLoader.load()
    }

    func testCountriesMinimumCount() {
        XCTAssertGreaterThanOrEqual(
            data.countries.count,
            195,
            "Expected at least 195 countries, got \(data.countries.count)"
        )
    }

    func testRiversMinimumCount() {
        XCTAssertGreaterThanOrEqual(
            data.rivers.count,
            30,
            "Expected at least 30 rivers, got \(data.rivers.count)"
        )
    }

    func testMountainsMinimumCount() {
        XCTAssertGreaterThanOrEqual(
            data.mountains.count,
            20,
            "Expected at least 20 mountain ranges, got \(data.mountains.count)"
        )
    }

    func testSeasMinimumCount() {
        XCTAssertGreaterThanOrEqual(
            data.seas.count,
            15,
            "Expected at least 15 seas/oceans, got \(data.seas.count)"
        )
    }

    func testCountryFieldsAreNonEmpty() {
        for country in data.countries {
            XCTAssertFalse(country.id.isEmpty, "Country has empty id")
            XCTAssertFalse(country.name.isEmpty, "Country \(country.id) has empty name")
            XCTAssertFalse(country.capital.isEmpty, "Country \(country.id) has empty capital")
            XCTAssertFalse(country.continent.isEmpty, "Country \(country.id) has empty continent")
        }
    }

    func testRiverFieldsAreNonEmpty() {
        for river in data.rivers {
            XCTAssertFalse(river.id.isEmpty, "River has empty id")
            XCTAssertFalse(river.name.isEmpty, "River \(river.id) has empty name")
            XCTAssertFalse(river.continent.isEmpty, "River \(river.id) has empty continent")
        }
    }

    func testMountainFieldsAreNonEmpty() {
        for mountain in data.mountains {
            XCTAssertFalse(mountain.id.isEmpty, "Mountain has empty id")
            XCTAssertFalse(mountain.name.isEmpty, "Mountain \(mountain.id) has empty name")
            XCTAssertFalse(mountain.highestPeak.isEmpty, "Mountain \(mountain.id) has empty highestPeak")
            XCTAssertGreaterThan(mountain.elevationMetres, 0, "Mountain \(mountain.id) has non-positive elevation")
        }
    }

    func testSeaFieldsAreNonEmpty() {
        for sea in data.seas {
            XCTAssertFalse(sea.id.isEmpty, "Sea has empty id")
            XCTAssertFalse(sea.name.isEmpty, "Sea \(sea.id) has empty name")
        }
    }

    func testCountryIdsAreUnique() {
        let ids = data.countries.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Country ids are not unique")
    }

    func testContinentsAreValid() {
        let valid = Set(["Africa", "Asia", "Europe", "North America", "Oceania", "South America", "Antarctica"])
        for country in data.countries {
            XCTAssertTrue(
                valid.contains(country.continent),
                "\(country.name) has unexpected continent: \(country.continent)"
            )
        }
    }

    func testKnownCountriesPresent() {
        let ids = Set(data.countries.map(\.id))
        XCTAssertTrue(ids.contains("US"), "United States missing")
        XCTAssertTrue(ids.contains("CN"), "China missing")
        XCTAssertTrue(ids.contains("DE"), "Germany missing")
        XCTAssertTrue(ids.contains("BR"), "Brazil missing")
        XCTAssertTrue(ids.contains("NG"), "Nigeria missing")
        XCTAssertTrue(ids.contains("AU"), "Australia missing")
        XCTAssertTrue(ids.contains("JP"), "Japan missing")
    }

    func testKnownRiversPresent() {
        let ids = Set(data.rivers.map(\.id))
        XCTAssertTrue(ids.contains("nile"), "Nile missing")
        XCTAssertTrue(ids.contains("amazon"), "Amazon missing")
        XCTAssertTrue(ids.contains("yangtze"), "Yangtze missing")
    }

    func testKnownMountainsPresent() {
        let ids = Set(data.mountains.map(\.id))
        XCTAssertTrue(ids.contains("himalayas"), "Himalayas missing")
        XCTAssertTrue(ids.contains("andes"), "Andes missing")
        XCTAssertTrue(ids.contains("alps"), "Alps missing")
    }

    func testKnownSeasPresent() {
        let ids = Set(data.seas.map(\.id))
        XCTAssertTrue(ids.contains("pacific"), "Pacific Ocean missing")
        XCTAssertTrue(ids.contains("mediterranean"), "Mediterranean Sea missing")
    }

    // MARK: - Korean / Nahuatl content (story 003)

    /// Korean country names and capitals decode from the bundled JSON and surface via localizedName.
    func testKoreanCountryContentDecoded() throws {
        let mexico = try XCTUnwrap(data.countries.first { $0.id == "MX" })
        XCTAssertEqual(mexico.localizedName(for: .ko), "멕시코")
        XCTAssertEqual(mexico.localizedCapital(for: .ko), "멕시코시티")

        let japan = try XCTUnwrap(data.countries.first { $0.id == "JP" })
        XCTAssertEqual(japan.localizedName(for: .ko), "일본")
    }

    /// Nahuatl uses its own value where present and otherwise falls back to Mexican Spanish (es-MX),
    /// never English, for the bundled data.
    func testNahuatlCountryFallsBackThroughSpanish() throws {
        let mexico = try XCTUnwrap(data.countries.first { $0.id == "MX" })
        XCTAssertEqual(mexico.localizedName(for: .nah), "Mēxihco", "Mexico has a Nahuatl name")

        // A country without a Nahuatl name should fall back to its Mexican Spanish name.
        let germany = try XCTUnwrap(data.countries.first { $0.id == "DE" })
        XCTAssertNil(germany.nameNah)
        XCTAssertEqual(germany.localizedName(for: .nah), germany.nameEs)
        XCTAssertNotEqual(germany.localizedName(for: .nah), germany.name, "Should not fall through to English")
    }

    /// Korean coverage is complete for geographic content (every entry has a Korean name).
    func testKoreanCoverageComplete() {
        for country in data.countries {
            XCTAssertNotNil(country.nameKo, "Country \(country.id) missing name_ko")
            XCTAssertNotNil(country.capitalKo, "Country \(country.id) missing capital_ko")
        }
        for river in data.rivers {
            XCTAssertNotNil(river.nameKo, "River \(river.id) missing name_ko")
        }
        for sea in data.seas {
            XCTAssertNotNil(sea.nameKo, "Sea \(sea.id) missing name_ko")
        }
        for mountain in data.mountains {
            XCTAssertNotNil(mountain.nameKo, "Mountain \(mountain.id) missing name_ko")
        }
    }
}
