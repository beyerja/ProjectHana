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
