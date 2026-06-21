import Foundation

/// The first, always-available ``LanguagePackProvider`` — sources everything from resources that
/// ship inside the app today, so the app is fully usable with ZERO downloaded packs.
///
/// - UI strings come from the base-language `.lproj` resolved by ``L10n/bundle(for:)`` (reusing the
///   existing fallback-chain logic in ``L10n/bundleCandidates(for:)``).
/// - Geo-name data is built from the bundled geo JSON (`countries.json`/`rivers.json`/
///   `mountains.json`/`seas.json`, already loaded by ``GeographyDataLoader``) into a
///   ``GeoNamePackData`` per language, round-tripped through ``GeoNamePackLoader`` so the bundled
///   path exercises the same schema validation as future ODR/CDN packs.
/// - Every base/bundled language reports ``LanguagePackState/available``.
///
/// On any pack-data build/validation failure for a language the provider returns `nil` geo data for
/// that language, so callers fall back to the bundled English/base names and the app never crashes.
struct BundledLanguagePackProvider: LanguagePackProvider {
    /// Validated per-language packs, keyed by language code, built once from the geo data at init.
    private let packsByCode: [String: GeoNamePackData]

    init(geography: GeographyData = GeographyDataLoader.shared) {
        packsByCode = Self.buildPacks(from: geography)
    }

    func stringBundle(for locale: AppLocale) -> Bundle {
        L10n.bundle(for: locale)
    }

    func geoNameData(for locale: AppLocale) -> GeoNamePackData? {
        packsByCode[locale.rawValue]
    }

    func state(for _: AppLocale) -> LanguagePackState {
        // Every language is served from in-app resources, so a pack is always available — there is
        // nothing to download. The seam reports a single state so call sites need not special-case.
        .available
    }

    // MARK: - Pack building

    /// Build one validated ``GeoNamePackData`` per non-base language from the bundled geo data.
    ///
    /// Only the per-language translation columns (fr/de/es-MX/ko/nah) become packs; the English base
    /// name lives on the geo model itself and is the resolver's final fallback, so it needs no pack.
    /// Each candidate pack is run through ``GeoNamePackLoader/validate(_:)`` and dropped (rather than
    /// crashing) if it fails validation.
    private static func buildPacks(from geography: GeographyData) -> [String: GeoNamePackData] {
        let packLanguages: [AppLocale] = [.fr, .de, .esMX, .ko, .nah]
        var result: [String: GeoNamePackData] = [:]
        for locale in packLanguages {
            let entries = entries(for: locale, in: geography)
            guard !entries.isEmpty else {
                continue
            }
            let pack = GeoNamePackData(code: locale.rawValue, entries: entries)
            if (try? GeoNamePackLoader.validate(pack)) != nil {
                result[locale.rawValue] = pack
            }
        }
        return result
    }

    /// Collect the geo entries for one language across all geo categories. An entry is included only
    /// when it carries a name or capital for this language (empty entries are skipped so validation
    /// passes).
    private static func entries(
        for locale: AppLocale,
        in geography: GeographyData
    ) -> [String: GeoNamePackData.GeoNameEntry] {
        var entries: [String: GeoNamePackData.GeoNameEntry] = [:]
        for country in geography.countries {
            let name = country.rawName(for: locale)
            let capital = country.rawCapital(for: locale)
            if name != nil || capital != nil {
                entries[country.id] = GeoNamePackData.GeoNameEntry(name: name, capital: capital)
            }
        }
        for river in geography.rivers where river.rawName(for: locale) != nil {
            entries[river.id] = GeoNamePackData.GeoNameEntry(name: river.rawName(for: locale))
        }
        for mountain in geography.mountains where mountain.rawName(for: locale) != nil {
            entries[mountain.id] = GeoNamePackData.GeoNameEntry(name: mountain.rawName(for: locale))
        }
        for sea in geography.seas where sea.rawName(for: locale) != nil {
            entries[sea.id] = GeoNamePackData.GeoNameEntry(name: sea.rawName(for: locale))
        }
        return entries
    }
}
