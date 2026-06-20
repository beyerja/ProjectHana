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
}
