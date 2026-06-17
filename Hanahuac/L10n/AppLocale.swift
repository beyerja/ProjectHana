import Foundation

enum AppLocale: String, CaseIterable, Identifiable {
    case en
    case fr
    case de
    case esMX = "es-MX"
    case ko
    case nah

    var id: String {
        rawValue
    }

    /// The language's native display name shown in the language picker.
    var displayName: String {
        switch self {
        case .en: "English"
        case .fr: "Français"
        case .de: "Deutsch"
        case .esMX: "Español (México)"
        case .ko: "한국어"
        case .nah: "Nāhuatl"
        }
    }

    /// Languages whose content/UI-string fallback chain is selected → Mexican Spanish (`es-MX`) →
    /// English, rather than the historical selected → English used by `fr`/`de`. These are the
    /// languages added with partial translation coverage, for which Mexican Spanish is a closer
    /// fallback than English (see feature spec: new language → es-MX → en).
    var fallsBackThroughSpanish: Bool {
        switch self {
        case .ko, .nah: true
        case .en, .fr, .de, .esMX: false
        }
    }

    /// Resolve a `Locale` to the best-matching `AppLocale`.
    ///
    /// Resolution order:
    /// 1. Any `es-*` locale maps to `.esMX`.
    /// 2. Match by language code (`en`, `fr`, `de`, `ko`, and the Nahuatl codes → `.nah`).
    /// 3. Fall back to `.en` for unrecognized locales.
    static func matching(_ locale: Locale) -> AppLocale {
        let language: String = if #available(iOS 16, macOS 13, *) {
            locale.language.languageCode?.identifier ?? ""
        } else {
            locale.languageCode ?? ""
        }

        // All Spanish variants map to esMX
        if language == "es" {
            return .esMX
        }

        switch language {
        case "en": return .en
        case "fr": return .fr
        case "de": return .de
        case "ko": return .ko
        // Generic Nahuatl: the macrolanguage code `nah` plus the common individual-language
        // ISO 639-3 codes that fall under it (e.g. `nhn` Central Nahuatl, `nch` Central Huasteca).
        case "nah", "nhn", "nch", "ncj", "ngu", "nhe": return .nah
        default: return .en
        }
    }
}
