import Foundation

/// Resolves a localized string using the bundle for the currently selected `AppLocale`,
/// bypassing the system locale so that in-app language switching takes effect immediately.
///
/// Usage (returns `String`):
/// ```swift
/// Text(L10n.string("home.categories"))
/// ```
/// Or via the shorthand static subscript:
/// ```swift
/// Text(L10n["home.categories"])
/// ```
enum L10n {
    /// Sentinel returned by `localizedString` when a key is absent from a bundle's table, letting us
    /// detect a miss and fall through to the next candidate bundle.
    private static let missing = "\u{0}__L10n_missing__\u{0}"

    /// Return the localized string for `key` in the bundle matching `LanguageManager.shared.current`.
    static func string(_ key: String) -> String {
        string(key, locale: LanguageManager.shared.current)
    }

    /// Return the localized string for `key`, resolving through `locale`'s fallback chain.
    ///
    /// For partially translated locales (`ko`/`nah`) the chain is selected language → Mexican
    /// Spanish (`es-MX`) → English, so a key missing from the selected `.lproj` is served from the
    /// es-MX table when present, otherwise from English. Fully translated locales resolve from their
    /// own table with English as the final safety net.
    static func string(_ key: String, locale: AppLocale) -> String {
        for code in bundleCandidates(for: locale) {
            guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                continue
            }
            let value = bundle.localizedString(forKey: key, value: missing, table: nil)
            if value != missing {
                return value
            }
        }
        // Nothing matched (e.g. the key exists in no bundle): return the key, matching Apple's
        // default behavior so callers still get a stable, debuggable string.
        return key
    }

    static subscript(_ key: String) -> String {
        string(key)
    }

    // MARK: - Internal

    /// The ordered `.lproj` resource codes to consult for `locale`.
    ///
    /// `ko`/`nah` fall through Mexican Spanish before English (`["ko", "es-MX", "en"]`); the
    /// established locales keep their historical selected → English chain.
    static func bundleCandidates(for locale: AppLocale) -> [String] {
        if locale.fallsBackThroughSpanish {
            return [locale.rawValue, AppLocale.esMX.rawValue, AppLocale.en.rawValue]
        }
        return [locale.rawValue, AppLocale.en.rawValue]
    }

    /// Returns the sub-bundle inside the main bundle that provides strings for `locale` — the first
    /// existing `.lproj` in the fallback chain. Retained for callers that need a `Bundle` directly;
    /// per-key fallback across the chain is handled by `string(_:locale:)`.
    static func bundle(for locale: AppLocale) -> Bundle {
        for code in bundleCandidates(for: locale) {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .main
    }
}
