import Foundation

/// Static metadata for one in-app language, used to drive the language picker, the L10n string
/// fallback chain, and (in later stories) the geo-name resolver from a single data source rather
/// than per-language `switch` statements scattered across the code base.
///
/// This is a pure value type: it carries data only and contains no logic. The single source of
/// truth for the full set of descriptors is ``LanguageCatalog``.
struct LanguageDescriptor: Equatable {
    /// Whether a language's localized resources ship inside the app binary or are downloaded on
    /// demand. Defined here for consumption by later stories (the language-pack provider / picker);
    /// the catalog re-architecture itself does not change behavior based on this flag.
    enum Availability: Equatable {
        /// A base language whose `.lproj` resources are always bundled in the app (en, es-MX).
        case bundledBase
        /// A language whose resources are delivered as a downloadable pack (fr, de, ko, nah).
        case downloadablePack
    }

    /// The script's writing direction. Drives the app's `layoutDirection` so the whole UI mirrors
    /// when a right-to-left language is selected (Arabic, Urdu), independently of the device locale.
    /// The single source of truth is this catalog field; ``AppLocale/isRTL`` reads it.
    enum TextDirection: Equatable {
        /// Left-to-right scripts (the default for every language except ar/ur).
        case leftToRight
        /// Right-to-left scripts (Arabic `ar`, Urdu `ur`).
        case rightToLeft
    }

    /// The language's stable code. Matches the corresponding ``AppLocale/rawValue`` (e.g. `"en"`,
    /// `"es-MX"`, `"nah"`) and the name of the language's `.lproj` resource directory.
    let code: String

    /// The language's native display name shown in the language picker (e.g. `"한국어"`,
    /// `"Español (México)"`). Presented in the language's own script, never translated.
    let displayName: String

    /// The ordered chain of locales to consult when resolving a localized string, from most to
    /// least preferred. The first entry is always the language itself. Partially translated
    /// languages (ko, nah) route through Mexican Spanish before English (selected → es-MX → en);
    /// fully translated non-base languages (fr, de) fall straight back to English (selected → en);
    /// the English base resolves to itself (`[en]`) and the Spanish base to `[es-MX, en]`.
    let fallbackChain: [AppLocale]

    /// Whether this language is a bundled base language or a downloadable pack. Drives later
    /// stories' download UI; has no effect on the L10n fallback behavior re-architected here.
    let availability: Availability

    /// The On-Demand-Resources tag(s) that deliver this language's downloadable pack (`.lproj` UI
    /// strings plus geo-name JSON), or an empty set for ``Availability/bundledBase`` languages, which
    /// ship in the app and are NEVER requested over ODR. Story 004's ODR provider keys its
    /// `NSBundleResourceRequest` off these tags. By convention the tag for a downloadable language is
    /// `"lang-<code>"` (e.g. `"lang-fr"`).
    let odrTags: Set<String>

    /// The language's writing direction. Defaults to ``TextDirection/leftToRight``; only the RTL
    /// languages (ar, ur) declare ``TextDirection/rightToLeft``. Read by ``AppLocale/isRTL`` to drive
    /// the app's `layoutDirection`.
    let textDirection: TextDirection

    init(
        code: String,
        displayName: String,
        fallbackChain: [AppLocale],
        availability: Availability,
        odrTags: Set<String>? = nil,
        textDirection: TextDirection = .leftToRight
    ) {
        self.code = code
        self.displayName = displayName
        self.fallbackChain = fallbackChain
        self.availability = availability
        self.textDirection = textDirection
        // Base languages never carry tags; downloadable packs default to the conventional
        // `"lang-<code>"` tag when not given an explicit set.
        if let odrTags {
            self.odrTags = odrTags
        } else {
            self.odrTags = availability == .downloadablePack ? ["lang-\(code)"] : []
        }
    }
}
