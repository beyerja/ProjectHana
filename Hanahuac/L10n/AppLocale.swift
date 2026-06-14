import Foundation

enum AppLocale: String, CaseIterable, Identifiable {
    case en   = "en"
    case fr   = "fr"
    case de   = "de"
    case esMX = "es-MX"

    var id: String { rawValue }

    /// The language's native display name shown in the language picker.
    var displayName: String {
        switch self {
        case .en:   return "English"
        case .fr:   return "Français"
        case .de:   return "Deutsch"
        case .esMX: return "Español (México)"
        }
    }

    /// Resolve a `Locale` to the best-matching `AppLocale`.
    ///
    /// Resolution order:
    /// 1. Any `es-*` locale maps to `.esMX`.
    /// 2. Match by language code (`en`, `fr`, `de`).
    /// 3. Fall back to `.en` for unrecognized locales.
    static func matching(_ locale: Locale) -> AppLocale {
        let language: String
        if #available(iOS 16, macOS 13, *) {
            language = locale.language.languageCode?.identifier ?? ""
        } else {
            language = locale.languageCode ?? ""
        }

        // All Spanish variants map to esMX
        if language == "es" {
            return .esMX
        }

        switch language {
        case "en": return .en
        case "fr": return .fr
        case "de": return .de
        default:   return .en
        }
    }
}
