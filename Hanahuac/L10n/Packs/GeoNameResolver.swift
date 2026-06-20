import Foundation

/// Resolves a localized geo name/capital from per-language values by walking a locale's
/// `fallbackChain`, replacing the former hardcoded per-locale `switch` arms on each geo model.
///
/// The geo models build a `[languageCode: value]` map from their own data (which, for the bundled
/// provider, originates in the bundled geo JSON) and hand it to this resolver. The resolver then
/// consults each code in `locale.fallbackChain` in order, returning the first non-empty value, and
/// finally the always-present base (`base`) value as the safety net. This is the single place that
/// knows the resolution algorithm, so adding a language is a catalog change, not a new `switch` arm.
enum GeoNameResolver {
    /// Resolve `locale`'s value from `byCode`, walking `locale.fallbackChain` and falling back to
    /// `base` (the English/base name) when no entry in the chain has a value.
    ///
    /// - Parameters:
    ///   - locale: The active language.
    ///   - byCode: Per-language values keyed by ``AppLocale/rawValue`` (e.g. `["fr": "Rhin"]`).
    ///   - base: The always-present base-language value used as the final fallback.
    static func resolve(_ locale: AppLocale, byCode: [String: String], base: String) -> String {
        for code in locale.fallbackChain.map(\.rawValue) {
            if let value = byCode[code], !value.isEmpty {
                return value
            }
        }
        return base
    }

    /// Which field of a pack entry to read — a geo's localized name, or (countries only) its capital.
    enum Field {
        case name
        case capital

        func value(in entry: GeoNamePackData.GeoNameEntry) -> String? {
            switch self {
            case .name:
                entry.name
            case .capital:
                entry.capital
            }
        }
    }

    /// Resolve a geo entry's localized value by walking `locale.fallbackChain` across the ACTIVE
    /// provider's pack data, keyed by the stable geo `id`.
    ///
    /// For each code in the chain (selected → es-MX for ko/nah → en) this asks `provider` for that
    /// language's ``GeoNamePackData`` and returns the first non-empty `entries[id]` value. When the
    /// provider has no pack for a code (`geoNameData` returns `nil` — e.g. a pack not yet downloaded,
    /// or a pack that failed schema validation), or the pack omits this id, that code is skipped and
    /// resolution falls through to the next code, and finally to `base` (the model's bundled
    /// English/base value). This never crashes and never returns a broken value when a pack is absent.
    ///
    /// - Parameters:
    ///   - id: The stable geo id (e.g. `"DE"`, `"rhine"`).
    ///   - locale: The active language.
    ///   - field: Whether to read the entry's `name` or `capital`.
    ///   - base: The always-present base-language value used as the final fallback.
    ///   - provider: The provider to consult; defaults to ``LanguagePackProviderHolder/active``.
    static func resolveThroughProvider(
        id: String,
        locale: AppLocale,
        field: Field,
        base: String,
        provider: LanguagePackProvider = LanguagePackProviderHolder.active
    ) -> String {
        for code in locale.fallbackChain {
            guard let pack = provider.geoNameData(for: code),
                  let entry = pack.entries[id],
                  let value = field.value(in: entry),
                  !value.isEmpty else {
                continue
            }
            return value
        }
        return base
    }
}
