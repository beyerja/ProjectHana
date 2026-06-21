import XCTest
@testable import Hanahuac

/// Behavior of the bundled `LanguagePackProvider`: works with zero downloaded packs, returns the
/// correct string source and geo-name data per language, and degrades safely on bad pack data.
final class BundledLanguagePackProviderTests: XCTestCase {
    private var provider: BundledLanguagePackProvider!

    override func setUp() {
        super.setUp()
        provider = BundledLanguagePackProvider()
    }

    // MARK: - Availability

    /// With only the bundled provider (zero downloads), every language reports available.
    func testState_everyLanguage_isAvailableWithZeroDownloads() {
        for locale in AppLocale.allCases {
            XCTAssertEqual(provider.state(for: locale), .available, "\(locale.rawValue) not available")
        }
    }

    // MARK: - String source

    func testStringBundle_matchesL10nResolution() {
        for locale in AppLocale.allCases {
            XCTAssertEqual(
                provider.stringBundle(for: locale).bundlePath,
                L10n.bundle(for: locale).bundlePath,
                "string bundle for \(locale.rawValue) should mirror L10n.bundle(for:)"
            )
        }
    }

    // MARK: - Geo-name data per language

    /// The provider exposes validated pack data for the translation languages, built from the
    /// bundled JSON; English has no pack (it is the resolver's base fallback).
    func testGeoNameData_translationLanguages_havePacks() {
        for locale in [AppLocale.fr, .de, .esMX, .ko, .nah] {
            let pack = provider.geoNameData(for: locale)
            XCTAssertNotNil(pack, "expected a pack for \(locale.rawValue)")
            XCTAssertEqual(pack?.code, locale.rawValue)
            XCTAssertFalse(pack?.entries.isEmpty ?? true, "pack for \(locale.rawValue) is empty")
        }
        XCTAssertNil(provider.geoNameData(for: .en), "English should have no pack (base fallback)")
    }

    func testGeoNameData_packDataMatchesModelFields() throws {
        let data = GeographyDataLoader.shared
        let mexico = try XCTUnwrap(data.countries.first { $0.id == "MX" })
        let koPack = try XCTUnwrap(provider.geoNameData(for: .ko))
        let entry = try XCTUnwrap(koPack.entries["MX"])
        XCTAssertEqual(entry.name, mexico.nameKo)
        XCTAssertEqual(entry.capital, mexico.capitalKo)
    }

    /// All bundled packs pass schema validation, proving the bundled path exercises the same loader
    /// that ODR/CDN packs will.
    func testGeoNameData_allBundledPacksAreValid() throws {
        for locale in [AppLocale.fr, .de, .esMX, .ko, .nah] {
            let pack = try XCTUnwrap(provider.geoNameData(for: locale))
            XCTAssertNoThrow(try GeoNamePackLoader.validate(pack), "\(locale.rawValue) pack invalid")
        }
    }

    // MARK: - Degrades safely

    /// An empty geo dataset yields no packs and no crash — the app would fall back to base names.
    func testProvider_withEmptyGeography_returnsNoPacksAndDoesNotCrash() {
        let empty = GeographyData(countries: [], rivers: [], mountains: [], seas: [])
        let bare = BundledLanguagePackProvider(geography: empty)
        for locale in AppLocale.allCases {
            XCTAssertNil(bare.geoNameData(for: locale), "empty geography should yield no pack")
            XCTAssertEqual(bare.state(for: locale), .available)
        }
    }
}
