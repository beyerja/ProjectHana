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

    /// es-ES ships a COMPLETE UI string set: zero keys missing relative to the English base. Uses the
    /// STRICT path: rather than silently returning the empty set when the es-ES `.lproj` is not
    /// mounted, the strict helper THROWS ``CompletenessError/stringBundleUnreachable``. We translate
    /// that distinct "pack unreachable" signal into an `XCTSkip` (matching every other ODR content
    /// test in this suite — the simulator unit-test host has no asset-pack server), so the test never
    /// degrades to a false pass. When the pack IS mounted, a genuine missing key FAILS the assertion.
    func testSpainSpanishHasNoMissingUIKeys() throws {
        let missing: Set<String>
        do {
            missing = try LanguageCompletenessSupport.missingUIKeysStrict(for: .esES)
        } catch let error as LanguageCompletenessSupport.CompletenessError {
            throw XCTSkip("es-ES UI strings not reachable in this environment: \(error)")
        }
        XCTAssertTrue(
            missing.isEmpty,
            "es-ES must define every English UI key (no missing keys)"
        )
    }

    /// es-ES ships COMPLETE geo coverage: every country/capital/river/mountain/sea has a Castilian
    /// name, so the bundled provider's pack reports no gaps for .esES. Uses the STRICT path, so a
    /// missing/nil es-ES pack FAILS (throws) rather than reporting a degenerate empty/whole-set report.
    func testSpainSpanishHasFullGeoCoverage() throws {
        let report = try LanguageCompletenessSupport.geoCoverageGapsStrict(for: .esES)
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

    // MARK: - Strict-path teeth (AC#2): a real gap FAILS rather than degrading to pass

    /// Restore the active provider after any test that swaps it, so a swapped stub never leaks into
    /// another test (the holder is process-wide).
    private var savedProvider: LanguagePackProvider?

    override func tearDown() {
        if let savedProvider {
            LanguagePackProviderHolder.active = savedProvider
            self.savedProvider = nil
        }
        super.tearDown()
    }

    /// Proves the STRICT geo path has teeth: with a stub provider that returns `nil` geo data for an
    /// enforced (downloadable, non-base) locale, ``geoCoverageGapsStrict(for:)`` must THROW
    /// ``LanguageCompletenessSupport/CompletenessError/geoPackUnreachable`` rather than degrading to a
    /// pass. This is the synthetic gap that AC#2 requires the gate to catch.
    func testStrictGeoPathThrowsOnSyntheticMissingPack() {
        savedProvider = LanguagePackProviderHolder.active
        LanguagePackProviderHolder.active = NilPackStubProvider()

        XCTAssertThrowsError(
            try LanguageCompletenessSupport.geoCoverageGapsStrict(for: .esES),
            "strict geo path must fail when an enforced locale's pack is unreachable"
        ) { error in
            XCTAssertEqual(
                error as? LanguageCompletenessSupport.CompletenessError,
                .geoPackUnreachable(locale: AppLocale.esES.rawValue)
            )
        }
    }

    /// The LENIENT geo path must NOT be perturbed by the same nil-pack stub: it degrades to reporting
    /// the whole geo set as gaps without throwing, confirming the strict/lenient split is intact.
    func testLenientGeoPathDoesNotThrowOnSyntheticMissingPack() {
        savedProvider = LanguagePackProviderHolder.active
        LanguagePackProviderHolder.active = NilPackStubProvider()

        // No throw, and a base locale still short-circuits to the empty report.
        XCTAssertEqual(LanguageCompletenessSupport.geoCoverageGaps(for: .esMX), .empty)
        let report = LanguageCompletenessSupport.geoCoverageGaps(for: .esES)
        XCTAssertFalse(
            report.geoEntitiesMissingName.isEmpty,
            "lenient path with a nil-pack provider should report gaps, not crash or throw"
        )
    }
}

/// A test double that resolves NO geo pack for any locale (and routes string lookups to the main
/// bundle), used to prove the strict completeness path FAILS on a synthetic gap. Restored in
/// `tearDown` by the swapping test.
private struct NilPackStubProvider: LanguagePackProvider {
    func stringBundle(for _: AppLocale) -> Bundle {
        .main
    }

    func geoNameData(for _: AppLocale) -> GeoNamePackData? {
        nil
    }

    func state(for _: AppLocale) -> LanguagePackState {
        .notDownloaded
    }
}
