import Foundation
import XCTest
@testable import Hanahuac

/// Reusable, dependency-free completeness scaffolding shared by every per-language story.
///
/// Given an ``AppLocale``, it reports which UI string keys are missing relative to the English base
/// `.lproj`, and which bundled geo entities (countries/rivers/mountains/seas) lack a localized
/// name/capital for that locale. Each per-language story (002–009) only ADDS a call/case — it never
/// restructures this file — so the stories never conflict on the same test bodies.
///
/// ## Two enforcement paths — lenient vs strict
/// Each completeness query comes in two flavors, so a caller picks the right enforcement bar:
///
/// - **Lenient** (``missingUIKeys(for:)`` / ``geoCoverageGaps(for:)``): degrades exactly like
///   ``ODRTestSupport`` — when a downloadable pack's `.lproj`/geo data is unreachable in the test
///   environment it returns the empty set / an empty report rather than failing, so a test that only
///   needs a *well-formed* answer (and legitimately tolerates an unmounted pack) skips cleanly instead
///   of producing a false negative. This is the right path for the generic well-formedness tests.
///
/// - **Strict** (``missingUIKeysStrict(for:)`` / ``geoCoverageGapsStrict(for:)``): distinguishes
///   "pack unreachable" from "no gaps". When a pack that is EXPECTED to be present (a downloadable,
///   non-base locale) cannot be resolved, the strict variant THROWS
///   (``CompletenessError/packUnreachable``) instead of silently returning the empty set, so a real
///   completeness gap — or a missing pack — fails CI rather than passing. The per-language
///   completeness assertions use this path; that is what gives the "no fallbacks" bar teeth.
enum LanguageCompletenessSupport {
    /// A strict-path failure: a pack expected to be present could not be resolved, so the strict
    /// completeness query cannot vouch for the locale and refuses to degrade to "no gaps".
    enum CompletenessError: Error, CustomStringConvertible, Equatable {
        /// The locale's UI-string `.lproj` bundle was expected but could not be resolved.
        case stringBundleUnreachable(locale: String)
        /// The locale's geo-name pack was expected (downloadable, non-base) but resolved to `nil`.
        case geoPackUnreachable(locale: String)

        var description: String {
            switch self {
            case let .stringBundleUnreachable(locale):
                "expected UI-string .lproj for '\(locale)' is unreachable "
                    + "(strict path refuses to degrade to the empty set)"
            case let .geoPackUnreachable(locale):
                "expected geo-name pack for '\(locale)' is unreachable / nil "
                    + "(strict path refuses to degrade to no-gaps)"
            }
        }
    }

    /// A structured completeness report for one locale.
    struct CompletenessReport: Equatable {
        /// UI string keys present in the base `en.lproj` but absent from this locale's `.lproj`.
        var missingUIKeys: Set<String>

        /// Geo entity ids (countries/rivers/mountains/seas) that carry no localized name for this
        /// locale (relative to the bundled source geo).
        var geoEntitiesMissingName: Set<String>

        /// Country ids that carry no localized capital for this locale.
        var countriesMissingCapital: Set<String>

        /// An empty report (used for the base locale, which is complete against itself by definition).
        static let empty = CompletenessReport(
            missingUIKeys: [],
            geoEntitiesMissingName: [],
            countriesMissingCapital: []
        )
    }

    // MARK: - UI string completeness

    /// The set of UI string keys present in `baseLocale`'s `.lproj` but missing from `locale`'s.
    ///
    /// The base locale (compared against itself) and any locale whose `.lproj` bundle cannot be
    /// resolved in this environment both return the empty set, so callers degrade like
    /// ``ODRTestSupport`` rather than reporting spurious gaps.
    static func missingUIKeys(for locale: AppLocale, baseLocale: AppLocale = .en) -> Set<String> {
        guard locale != baseLocale else {
            return []
        }
        guard let baseBundle = stringBundle(for: baseLocale),
              let localeBundle = stringBundle(for: locale) else {
            return []
        }
        let baseKeys = localizableKeys(in: baseBundle)
        let localeKeys = localizableKeys(in: localeBundle)
        return baseKeys.subtracting(localeKeys)
    }

    /// STRICT variant of ``missingUIKeys(for:)``: the set of UI string keys present in `baseLocale`'s
    /// `.lproj` but missing from `locale`'s, but THROWS ``CompletenessError/stringBundleUnreachable``
    /// when an EXPECTED locale's `.lproj` cannot be resolved instead of returning the empty set.
    ///
    /// The base locale (compared against itself) still returns the empty set. For any other locale the
    /// base bundle and the locale bundle must both resolve — an unreachable expected pack is a failure
    /// signal, not "no missing keys", so a genuine completeness gap (or a missing pack) fails CI.
    static func missingUIKeysStrict(
        for locale: AppLocale,
        baseLocale: AppLocale = .en
    ) throws -> Set<String> {
        guard locale != baseLocale else {
            return []
        }
        guard let baseBundle = stringBundle(for: baseLocale) else {
            throw CompletenessError.stringBundleUnreachable(locale: baseLocale.rawValue)
        }
        guard let localeBundle = stringBundle(for: locale) else {
            throw CompletenessError.stringBundleUnreachable(locale: locale.rawValue)
        }
        let baseKeys = localizableKeys(in: baseBundle)
        let localeKeys = localizableKeys(in: localeBundle)
        return baseKeys.subtracting(localeKeys)
    }

    // MARK: - Geo coverage completeness

    /// The geo-coverage gaps for `locale` relative to the bundled source geo.
    ///
    /// Drives off the active ``LanguagePackProvider``'s validated ``GeoNamePackData`` for `locale`, so
    /// any future pack is covered automatically by the generated pack schema. For a bundled-base
    /// locale (whose names live on the geo model itself, with no separate pack) the report is empty.
    static func geoCoverageGaps(
        for locale: AppLocale,
        geo: GeographyData = GeographyDataLoader.load()
    ) -> CompletenessReport {
        guard !locale.isBundledBaseLanguage else {
            return .empty
        }
        let pack = LanguagePackProviderHolder.active.geoNameData(for: locale)
        return coverageReport(for: locale, pack: pack, geo: geo)
    }

    /// STRICT variant of ``geoCoverageGaps(for:)``: the geo-coverage gaps for `locale`, but THROWS
    /// ``CompletenessError/geoPackUnreachable`` when an EXPECTED pack (a downloadable, non-base
    /// locale) resolves to `nil` instead of silently reporting the whole geo set as gaps.
    ///
    /// Under the default ``BundledLanguagePackProvider`` a downloadable locale always yields a
    /// non-nil pack, so the strict path proceeds with the real gaps; only a genuinely missing pack
    /// (or a stub that returns `nil`) throws. The ``AppLocale/isBundledBaseLanguage`` early-return is
    /// preserved — a base locale has no separate pack, so its report is empty.
    static func geoCoverageGapsStrict(
        for locale: AppLocale,
        geo: GeographyData = GeographyDataLoader.load()
    ) throws -> CompletenessReport {
        guard !locale.isBundledBaseLanguage else {
            return .empty
        }
        guard let pack = LanguagePackProviderHolder.active.geoNameData(for: locale) else {
            throw CompletenessError.geoPackUnreachable(locale: locale.rawValue)
        }
        return coverageReport(for: locale, pack: pack, geo: geo)
    }

    /// Compute the geo-coverage gaps for `locale` against `pack` (which may be `nil` on the lenient
    /// path). Shared by ``geoCoverageGaps(for:)`` and ``geoCoverageGapsStrict(for:)`` so the gap math
    /// lives in one place.
    private static func coverageReport(
        for _: AppLocale,
        pack: GeoNamePackData?,
        geo: GeographyData
    ) -> CompletenessReport {
        var missingName: Set<String> = []
        var missingCapital: Set<String> = []

        for country in geo.countries {
            let entry = pack?.entries[country.id]
            if isBlank(entry?.name) {
                missingName.insert(country.id)
            }
            if isBlank(entry?.capital) {
                missingCapital.insert(country.id)
            }
        }
        for id in geo.rivers.map(\.id) where isBlank(pack?.entries[id]?.name) {
            missingName.insert(id)
        }
        for id in geo.mountains.map(\.id) where isBlank(pack?.entries[id]?.name) {
            missingName.insert(id)
        }
        for id in geo.seas.map(\.id) where isBlank(pack?.entries[id]?.name) {
            missingName.insert(id)
        }

        return CompletenessReport(
            missingUIKeys: [],
            geoEntitiesMissingName: missingName,
            countriesMissingCapital: missingCapital
        )
    }

    // MARK: - Internal

    /// Resolve the `.lproj` `Bundle` for `locale` on the LENIENT path: the in-app bundle for
    /// bundled-base locales, the on-disk ODR asset pack for downloadable locales. Returns `nil` when a
    /// downloadable pack is not reachable in this environment (so the lenient caller degrades to the
    /// empty set). Behavior unchanged from before the strict path existed.
    private static func stringBundle(for locale: AppLocale) -> Bundle? {
        if locale.isBundledBaseLanguage {
            return L10n.bundle(for: locale)
        }
        return try? ODRTestSupport.lprojBundle(for: locale)
    }

    /// All keys defined in a bundle's `Localizable.strings` table, or the empty set when the table is
    /// absent/unreadable.
    private static func localizableKeys(in bundle: Bundle) -> Set<String> {
        guard let url = bundle.url(forResource: "Localizable", withExtension: "strings"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            return []
        }
        return Set(dict.keys)
    }

    /// Whether a localized value is absent or empty.
    private static func isBlank(_ value: String?) -> Bool {
        value?.isEmpty ?? true
    }
}
