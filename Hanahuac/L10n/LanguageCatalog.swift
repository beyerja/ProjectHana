import Foundation

/// The single source of truth for the set of in-app languages and their metadata.
///
/// Every consumer (the picker via ``AppLocale/allCases``, the L10n fallback chain in ``L10n``, and
/// later stories' geo-name resolver) derives its language list and fallback order from this catalog
/// rather than from duplicated per-language `switch` statements. Adding a language is, to the extent
/// feasible, a matter of adding a ``LanguageDescriptor`` entry here.
enum LanguageCatalog {
    /// All language descriptors, ordered to match ``AppLocale/allCases`` (en, fr, de, es-MX, es-ES,
    /// ca, eu, yua, it, ko, nah). The display names and fallback chains encode exactly the behavior of
    /// the former per-case `switch` statements in `AppLocale`.
    static let all: [LanguageDescriptor] = [
        LanguageDescriptor(
            code: AppLocale.en.rawValue,
            displayName: "English",
            fallbackChain: [.en],
            availability: .bundledBase
        ),
        LanguageDescriptor(
            code: AppLocale.fr.rawValue,
            displayName: "Français",
            fallbackChain: [.fr, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.de.rawValue,
            displayName: "Deutsch",
            fallbackChain: [.de, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.esMX.rawValue,
            displayName: "Español (México)",
            fallbackChain: [.esMX, .en],
            availability: .bundledBase
        ),
        LanguageDescriptor(
            code: AppLocale.esES.rawValue,
            displayName: "Español (España)",
            fallbackChain: [.esES, .esMX, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.ca.rawValue,
            displayName: "Català",
            fallbackChain: [.ca, .esES, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.eu.rawValue,
            displayName: "Euskara",
            fallbackChain: [.eu, .esES, .en],
            availability: .downloadablePack
        ),
        // Yucatec Maya is a best-effort, fallback-permitted language: genuine gaps in its UI/geo
        // content fall back through Mexican Spanish (es-MX) before English. It routes through es-MX
        // (matching `fallsBackThroughSpanish`), not es-ES.
        LanguageDescriptor(
            code: AppLocale.yua.rawValue,
            displayName: "Màaya t'àan",
            fallbackChain: [.yua, .esMX, .en],
            availability: .downloadablePack
        ),
        // Italian is a COMPLETE-content language: its UI strings and geo names are fully translated,
        // so its fallback chain routes straight to English as an ultimate, never-hit safety net
        // (NOT through es-MX/es-ES like the best-effort languages).
        LanguageDescriptor(
            code: AppLocale.it.rawValue,
            displayName: "Italiano",
            fallbackChain: [.it, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.ko.rawValue,
            displayName: "한국어",
            fallbackChain: [.ko, .esMX, .en],
            availability: .downloadablePack
        ),
        LanguageDescriptor(
            code: AppLocale.nah.rawValue,
            displayName: "Nāhuatl",
            fallbackChain: [.nah, .esMX, .en],
            availability: .downloadablePack
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
