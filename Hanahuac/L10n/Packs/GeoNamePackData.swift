import Foundation

/// The DATA-ONLY pack-data model for one language's geographic-name translations.
///
/// A "pack" carries one language's localized geo names (and, for countries, capitals) keyed by the
/// stable geo id used by ``Country``/``River``/``MountainRange``/``Sea``. It is intentionally pure
/// data: a versioned `Codable` value with no executable content, so it can be shipped bundled,
/// delivered on demand (ODR, story 004), or downloaded from a signed CDN (future) and decoded the
/// same way regardless of source. Nothing in a pack is ever executed — only strings are read.
///
/// The `version` field lets the loader reject packs produced by an incompatible future schema,
/// degrading safely to the bundled fallback rather than mis-decoding.
struct GeoNamePackData: Codable, Equatable {
    /// The schema versions this build understands. A pack whose `version` is not listed is rejected
    /// by the loader and the caller falls back to bundled names.
    static let supportedVersions: Set<Int> = [1]

    /// The current schema version emitted by this build.
    static let currentVersion: Int = 1

    /// One language's translation for a single geo entry. `capital` is only meaningful for countries
    /// (rivers, mountains, and seas have no capital); it is omitted from their entries.
    struct GeoNameEntry: Codable, Equatable {
        /// The localized name for this geo id in the pack's language, or `nil` when this language has
        /// no translation for it (the resolver then walks the fallback chain).
        let name: String?

        /// The localized capital for this geo id (countries only), or `nil` when absent.
        let capital: String?

        init(name: String?, capital: String? = nil) {
            self.name = name
            self.capital = capital
        }
    }

    /// The pack-data schema version. Validated against ``supportedVersions`` before use.
    let version: Int

    /// The language code this pack provides translations for (e.g. `"fr"`, `"ko"`, `"es-MX"`).
    /// Matches ``AppLocale/rawValue`` and the `.lproj` resource directory name.
    let code: String

    /// Translations keyed by geo id (the `id` on the geo model, e.g. `"DE"`, `"rhine"`, `"alps"`).
    let entries: [String: GeoNameEntry]

    init(version: Int = GeoNamePackData.currentVersion, code: String, entries: [String: GeoNameEntry]) {
        self.version = version
        self.code = code
        self.entries = entries
    }
}
