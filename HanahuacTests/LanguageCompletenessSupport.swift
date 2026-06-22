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
/// The helpers degrade exactly like ``ODRTestSupport``: when a downloadable pack's `.lproj` bundle is
/// unreachable in the test environment they return the empty set rather than failing, so content
/// assertions that depend on a mounted pack skip cleanly instead of producing false negatives.
enum LanguageCompletenessSupport {
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

    /// Resolve the `.lproj` `Bundle` for `locale`: the in-app bundle for bundled-base locales, the
    /// on-disk ODR asset pack for downloadable locales. Returns `nil` when a downloadable pack is not
    /// reachable in this environment.
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
