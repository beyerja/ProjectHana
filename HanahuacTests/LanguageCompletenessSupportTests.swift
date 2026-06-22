import XCTest
@testable import Hanahuac

/// Exercises ``LanguageCompletenessSupport`` on existing languages, satisfying AC#2 (the reusable
/// completeness helper is covered by at least one test on an existing language). Per-language stories
/// only ADD cases here; they never restructure these bodies.
final class LanguageCompletenessSupportTests: XCTestCase {
    /// The base locale compared against itself has, by definition, no missing UI keys.
    func testMissingUIKeysForBaseLocaleIsEmpty() {
        XCTAssertTrue(
            LanguageCompletenessSupport.missingUIKeys(for: .en).isEmpty,
            "English base vs itself must report no missing UI keys"
        )
    }

    /// A downloadable locale returns a well-formed key set — either the genuine gaps when its pack
    /// `.lproj` is reachable, or the empty set when the pack is not mounted in this environment. Either
    /// way the call must not crash and must yield a usable `Set<String>`.
    func testMissingUIKeysForDownloadableLocaleIsWellFormed() {
        let missing = LanguageCompletenessSupport.missingUIKeys(for: .fr)
        XCTAssertFalse(
            missing.contains(""),
            "missing-key set must never contain an empty string key"
        )
    }

    /// A bundled-base locale has no separate geo pack, so its coverage report is empty.
    func testGeoCoverageGapsForBaseLocaleIsEmpty() {
        XCTAssertEqual(LanguageCompletenessSupport.geoCoverageGaps(for: .esMX), .empty)
    }

    // MARK: - es-ES (Story 002) completeness

    /// es-ES ships a COMPLETE UI string set: zero keys missing relative to the English base. When the
    /// ODR `.lproj` pack is not mounted in this environment the helper degrades to the empty set, so
    /// either way there must be no missing keys.
    func testSpainSpanishHasNoMissingUIKeys() {
        XCTAssertTrue(
            LanguageCompletenessSupport.missingUIKeys(for: .esES).isEmpty,
            "es-ES must define every English UI key (no missing keys)"
        )
    }

    /// es-ES ships COMPLETE geo coverage: every country/capital/river/mountain/sea has a Castilian
    /// name, so the bundled provider's pack reports no gaps for .esES.
    func testSpainSpanishHasFullGeoCoverage() {
        let report = LanguageCompletenessSupport.geoCoverageGaps(for: .esES)
        XCTAssertTrue(
            report.geoEntitiesMissingName.isEmpty,
            "es-ES is missing geo names for: \(report.geoEntitiesMissingName.sorted())"
        )
        XCTAssertTrue(
            report.countriesMissingCapital.isEmpty,
            "es-ES is missing capitals for: \(report.countriesMissingCapital.sorted())"
        )
    }

    /// A downloadable locale yields a well-formed coverage report: the gap sets are constrained to the
    /// bundled source geo ids, and the helper returns rather than crashing regardless of pack state.
    func testGeoCoverageGapsForDownloadableLocaleIsWellFormed() {
        let geo = GeographyDataLoader.load()
        let knownIDs = Set(
            geo.countries.map(\.id) + geo.rivers.map(\.id) + geo.mountains.map(\.id) + geo.seas.map(\.id)
        )
        let report = LanguageCompletenessSupport.geoCoverageGaps(for: .fr, geo: geo)
        XCTAssertTrue(
            report.geoEntitiesMissingName.isSubset(of: knownIDs),
            "missing-name ids must be a subset of the bundled source geo ids"
        )
        let countryIDs = Set(geo.countries.map(\.id))
        XCTAssertTrue(
            report.countriesMissingCapital.isSubset(of: countryIDs),
            "missing-capital ids must be a subset of the bundled country ids"
        )
    }
}
