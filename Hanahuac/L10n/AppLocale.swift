import Foundation

enum AppLocale: String, CaseIterable, Identifiable {
    case en
    case fr
    case de
    case esMX = "es-MX"
    case esES = "es-ES"
    case ca
    case eu
    case yua
    case it
    case pl
    case nl
    case sr
    case ko
    case nah
    case ja
    case zhHans = "zh-Hans"
    case hi
    case ar
    case bn
    case ptBR = "pt-BR"
    case ur

    var id: String {
        rawValue
    }

    /// The catalog descriptor backing this language's metadata (display name, fallback chain,
    /// availability). The catalog is the single source of truth; properties below read from it
    /// instead of inline `switch` statements.
    private var descriptor: LanguageDescriptor {
        LanguageCatalog.descriptor(for: self)
    }

    /// The language's native display name shown in the language picker.
    var displayName: String {
        descriptor.displayName
    }

    /// The ordered chain of locales to consult when resolving a localized string, derived from the
    /// catalog descriptor (selected → es-MX → en for ko/nah; selected → en for fr/de; en → [en];
    /// es-MX → [es-MX, en]).
    var fallbackChain: [AppLocale] {
        descriptor.fallbackChain
    }

    /// Whether this language is a bundled base language (en, es-MX) whose `.lproj` resources ship in
    /// the app, as opposed to a downloadable pack (fr, de, ko, nah). Catalog-backed; defined for
    /// later stories and does not affect current L10n behavior.
    var isBundledBaseLanguage: Bool {
        descriptor.availability == .bundledBase
    }

    /// The On-Demand-Resources tag(s) that deliver this language's downloadable pack, or an empty set
    /// for bundled base languages (en, es-MX), which are NEVER requested over ODR. Catalog-backed;
    /// consumed by story 004's ODR provider to key its `NSBundleResourceRequest`.
    var odrTags: Set<String> {
        descriptor.odrTags
    }

    /// Languages whose content/UI-string fallback chain is selected → Mexican Spanish (`es-MX`) →
    /// English, rather than the historical selected → English used by `fr`/`de`. These are the
    /// languages added with partial translation coverage, for which Mexican Spanish is a closer
    /// fallback than English (see feature spec: new language → es-MX → en).
    ///
    /// Derived from the catalog's fallback chain (true when the chain routes through `es-MX` and the
    /// language is not itself `es-MX`) rather than a hand-maintained boolean `switch`.
    var fallsBackThroughSpanish: Bool {
        self != .esMX && fallbackChain.contains(.esMX)
    }

    /// Whether this language is written right-to-left (Arabic, Urdu), in which case the whole app's
    /// layout must mirror. Catalog-backed (reads ``LanguageDescriptor/textDirection``) so the RTL set
    /// lives in one place; SwiftUI wiring maps this to `\.environment(\.layoutDirection, …)`.
    ///
    /// This is the single, language-driven RTL signal — it derives from the SELECTED language, not the
    /// device locale, so forcing/selecting an RTL language flips the app even on an LTR device.
    var isRTL: Bool {
        descriptor.textDirection == .rightToLeft
    }

    /// Resolve a `Locale` to the best-matching `AppLocale`.
    ///
    /// Resolution order:
    /// 1. Any `es-*` locale maps to `.esMX` (unchanged — es-* never auto-selects es-ES).
    /// 2. The Nahuatl macrolanguage code plus its common ISO 639-3 individual codes map to `.nah`
    ///    (unchanged).
    /// 3. Any `zh*` locale (generic `zh`, `zh-Hans`, `zh-Hant`, `zh-CN`, …) maps to `.zhHans`, and any
    ///    `pt*` locale (generic `pt`, `pt-BR`, `pt-PT`, …) maps to `.ptBR`. These are the two
    ///    macrolanguage → regional mappings the catalog code-lookup cannot express, mirroring the
    ///    `es` → `.esMX` pattern.
    /// 4. Match by language code against the catalog (`en`, `fr`, `de`, `ca`, `eu`, `yua`, `it`, `pl`,
    ///    `nl`, `sr`, `ko`, plus the regional-code-free new languages `ja`, `hi`, `ar`, `bn`, `ur`); a
    ///    `ca` device locale auto-selects Catalan, an `eu` device locale auto-selects Basque, a `yua`
    ///    device locale auto-selects Yucatec Maya, an `it` device locale auto-selects Italian, a `pl`
    ///    device locale auto-selects Polish, an `nl` device locale auto-selects Dutch, an `sr` device
    ///    locale auto-selects Serbian (Cyrillic), and `ja`/`hi`/`ar`/`bn`/`ur` device locales
    ///    auto-select Japanese/Hindi/Arabic/Bengali/Urdu — all via this code lookup (code == rawValue),
    ///    without perturbing the es-* → es-MX or Nahuatl mappings above.
    /// 5. Fall back to `.en` for unrecognized locales.
    static func matching(_ locale: Locale) -> AppLocale {
        let language: String = if #available(iOS 16, macOS 13, *) {
            locale.language.languageCode?.identifier ?? ""
        } else {
            locale.languageCode ?? ""
        }

        // All Spanish variants map to esMX.
        if language == "es" {
            return .esMX
        }

        // Generic Nahuatl: the macrolanguage code `nah` plus the common individual-language
        // ISO 639-3 codes that fall under it (e.g. `nhn` Central Nahuatl, `nch` Central Huasteca).
        if nahuatlCodes.contains(language) {
            return .nah
        }

        // Generic Chinese (any zh* variant — zh, zh-Hans, zh-Hant, zh-CN, …) maps to Simplified
        // Chinese, mirroring the es → esMX collapse above (the catalog code lookup cannot express a
        // macrolanguage → regional-rawValue mapping).
        if language == "zh" {
            return .zhHans
        }

        // Generic Portuguese (any pt* variant — pt, pt-BR, pt-PT, …) maps to Brazilian Portuguese.
        if language == "pt" {
            return .ptBR
        }

        // Simple per-language-code cases resolve via the catalog's `code` lookup, so adding a
        // catalog entry is sufficient for codes that match their `AppLocale.rawValue` directly.
        if let descriptor = LanguageCatalog.all.first(where: { $0.code == language }),
           let matched = AppLocale(rawValue: descriptor.code) {
            return matched
        }

        return .en
    }

    /// The ISO 639-3 codes (plus the `nah` macrolanguage code) that all resolve to ``nah``.
    private static let nahuatlCodes: Set<String> = ["nah", "nhn", "nch", "ncj", "ngu", "nhe"]
}
