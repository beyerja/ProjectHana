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
    /// Return the localized string for `key` in the bundle matching `LanguageManager.shared.current`.
    static func string(_ key: String) -> String {
        bundle(for: LanguageManager.shared.current).localizedString(forKey: key, value: nil, table: nil)
    }

    /// Return the localized string for `key` in the bundle matching the given `locale`.
    static func string(_ key: String, locale: AppLocale) -> String {
        bundle(for: locale).localizedString(forKey: key, value: nil, table: nil)
    }

    static subscript(_ key: String) -> String {
        string(key)
    }

    // MARK: - Internal

    /// Returns the sub-bundle inside the main bundle that provides strings for `locale`.
    ///
    /// Apple stores `.lproj` directories inside the app bundle.  We locate the
    /// matching `<locale-code>.lproj` directory (or fall back to `en.lproj`) and
    /// wrap it in a `Bundle` so that `localizedString(forKey:…)` reads from that file.
    static func bundle(for locale: AppLocale) -> Bundle {
        // Try the exact locale code first, then "en" as the safety net.
        let candidates = [locale.rawValue, "en"]
        for code in candidates {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let b = Bundle(path: path) {
                return b
            }
        }
        return .main
    }
}
