import Foundation

/// The single source of truth for the set of in-app languages and their metadata.
///
/// Every consumer (the picker via ``AppLocale/allCases``, the L10n fallback chain in ``L10n``, and
/// later stories' geo-name resolver) derives its language list and fallback order from this catalog
/// rather than from duplicated per-language `switch` statements. Adding a language is, to the extent
/// feasible, a matter of adding a ``LanguageDescriptor`` entry here.
enum LanguageCatalog {
    /// All language descriptors, ordered to match ``AppLocale/allCases`` (en, fr, de, es-MX, es-ES,
    /// ca, eu, yua, it, pl, nl, sr, ko, nah, ja, zh-Hans, hi, ar, bn, pt-BR, ur). The display names and
    /// fallback chains encode exactly the behavior of the former per-case `switch` statements in
    /// `AppLocale`. The 7 trailing locales (ja…ur) are content-pending: their UI strings and geo packs
    /// are placeholder/empty until their content story (003–010) fills them, but they are full
    /// COMPLETE-content languages by contract, so each routes straight to English as the ultimate,
    /// never-hit safety net.
    static let all: [LanguageDescriptor] = [
        LanguageDescriptor(
            code: AppLocale.en.rawValue,
            displayName: "English",
            englishName: "English",
            fallbackChain: [.en],
            availability: .bundledBase
        ),
        LanguageDescriptor(
            code: AppLocale.fr.rawValue,
            displayName: "Français",
            englishName: "French",
            fallbackChain: [.fr, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.de.rawValue,
            displayName: "Deutsch",
            englishName: "German",
            fallbackChain: [.de, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.esMX.rawValue,
            displayName: "Español (México)",
            englishName: "Spanish (Mexico)",
            fallbackChain: [.esMX, .en],
            availability: .bundledBase
        ),
        LanguageDescriptor(
            code: AppLocale.esES.rawValue,
            displayName: "Español (España)",
            englishName: "Spanish (Spain)",
            fallbackChain: [.esES, .esMX, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.ca.rawValue,
            displayName: "Català",
            englishName: "Catalan",
            fallbackChain: [.ca, .esES, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.eu.rawValue,
            displayName: "Euskara",
            englishName: "Basque",
            fallbackChain: [.eu, .esES, .en],
            availability: .downloadablePack
        ),
        // Yucatec Maya is a best-effort, fallback-permitted language: genuine gaps in its UI/geo
        // content fall back through Mexican Spanish (es-MX) before English. It routes through es-MX
        // (matching `fallsBackThroughSpanish`), not es-ES.
        LanguageDescriptor(
            code: AppLocale.yua.rawValue,
            displayName: "Màaya t'àan",
            englishName: "Yucatec Maya",
            fallbackChain: [.yua, .esMX, .en],
            availability: .downloadablePack
        ),
        // Italian is a COMPLETE-content language: its UI strings and geo names are fully translated,
        // so its fallback chain routes straight to English as an ultimate, never-hit safety net
        // (NOT through es-MX/es-ES like the best-effort languages).
        LanguageDescriptor(
            code: AppLocale.it.rawValue,
            displayName: "Italiano",
            englishName: "Italian",
            fallbackChain: [.it, .en],
            availability: .downloadablePack
        ),
        // Polish is a COMPLETE-content language: its UI strings and geo names are fully translated,
        // so its fallback chain routes straight to English as an ultimate, never-hit safety net
        // (NOT through es-MX/es-ES like the best-effort languages).
        LanguageDescriptor(
            code: AppLocale.pl.rawValue,
            displayName: "Polski",
            englishName: "Polish",
            fallbackChain: [.pl, .en],
            availability: .downloadablePack
        ),
        // Dutch is a COMPLETE-content language: its UI strings and geo names are fully translated,
        // so its fallback chain routes straight to English as an ultimate, never-hit safety net
        // (NOT through es-MX/es-ES like the best-effort languages).
        LanguageDescriptor(
            code: AppLocale.nl.rawValue,
            displayName: "Nederlands",
            englishName: "Dutch",
            fallbackChain: [.nl, .en],
            availability: .downloadablePack
        ),
        // Serbian is a COMPLETE-content language: its UI strings and geo names are fully translated,
        // so its fallback chain routes straight to English as an ultimate, never-hit safety net
        // (NOT through es-MX/es-ES like the best-effort languages).
        //
        // Script decision — Cyrillic ("Српски"): Serbian is officially digraphic, but Cyrillic is the
        // constitutionally designated official script of Serbian (Article 10 of the Constitution of
        // Serbia). Authoritative geographic names (country/capital/river/mountain/sea exonyms) are
        // best served by the official script, so all `sr` content — display name and geo data — is
        // authored in Cyrillic rather than Latin transliteration (feature spec §5).
        LanguageDescriptor(
            code: AppLocale.sr.rawValue,
            displayName: "Српски",
            englishName: "Serbian",
            fallbackChain: [.sr, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.ko.rawValue,
            displayName: "한국어",
            englishName: "Korean",
            fallbackChain: [.ko, .esMX, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.nah.rawValue,
            displayName: "Nāhuatl",
            englishName: "Nahuatl",
            fallbackChain: [.nah, .esMX, .en],
            availability: .downloadablePack
        ),
        // The 7 content-pending languages below are COMPLETE-content by contract: each routes straight
        // to English as an ultimate, never-hit safety net (NOT through es-MX/es-ES). Their UI strings
        // and geo packs are placeholder/empty until their content story (003–010) fills them.
        // odrTags are auto-derived from the rawValue (lang-<code>, e.g. lang-zh-Hans, lang-pt-BR).
        LanguageDescriptor(
            code: AppLocale.ja.rawValue,
            displayName: "日本語",
            englishName: "Japanese",
            fallbackChain: [.ja, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.zhHans.rawValue,
            displayName: "简体中文",
            englishName: "Chinese (Simplified)",
            fallbackChain: [.zhHans, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.hi.rawValue,
            displayName: "हिन्दी",
            englishName: "Hindi",
            fallbackChain: [.hi, .en],
            availability: .downloadablePack
        ),
        // Arabic is a right-to-left language: its descriptor declares `.rightToLeft` so selecting it
        // flips the whole app's `layoutDirection`, independently of the device locale. The RTL
        // infrastructure (story 008) lands before ar content, so this drives the mirrored layout the
        // moment ar is selectable.
        LanguageDescriptor(
            code: AppLocale.ar.rawValue,
            displayName: "العربية",
            englishName: "Arabic",
            fallbackChain: [.ar, .en],
            availability: .downloadablePack,
            textDirection: .rightToLeft
        ),
        LanguageDescriptor(
            code: AppLocale.bn.rawValue,
            displayName: "বাংলা",
            englishName: "Bengali",
            fallbackChain: [.bn, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.ptBR.rawValue,
            displayName: "Português (Brasil)",
            englishName: "Portuguese (Brazil)",
            fallbackChain: [.ptBR, .en],
            availability: .downloadablePack
        ),
        // Urdu is a right-to-left language: like Arabic it declares `.rightToLeft` so selecting it
        // mirrors the whole app's layout.
        LanguageDescriptor(
            code: AppLocale.ur.rawValue,
            displayName: "اردو",
            englishName: "Urdu",
            fallbackChain: [.ur, .en],
            availability: .downloadablePack,
            textDirection: .rightToLeft
        )
    ]

    /// The descriptor for `locale`. Every ``AppLocale`` case has exactly one catalog entry, so this
    /// is non-optional; a missing entry is a programmer error and traps.
    static func descriptor(for locale: AppLocale) -> LanguageDescriptor {
        guard let descriptor = all.first(where: { $0.code == locale.rawValue }) else {
            preconditionFailure("LanguageCatalog is missing a descriptor for \(locale.rawValue)")
        }
        return descriptor
    }
}
