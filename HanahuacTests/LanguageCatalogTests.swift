import XCTest
@testable import Hanahuac

/// Tests the data-driven ``LanguageCatalog`` and ``LanguageDescriptor`` that back ``AppLocale``'s
/// display names, fallback chains, and bundled/downloadable availability flag.
final class LanguageCatalogTests: XCTestCase {
    // MARK: - Catalog shape

    func testCatalogContainsExactlyTwentyOneLanguages() {
        XCTAssertEqual(LanguageCatalog.all.count, 21)
    }

    /// Catalog ordering must match `AppLocale.allCases` so the picker order is preserved.
    func testCatalogOrderMatchesAllCases() {
        let catalogCodes = LanguageCatalog.all.map(\.code)
        let appLocaleCodes = AppLocale.allCases.map(\.rawValue)
        XCTAssertEqual(catalogCodes, appLocaleCodes)
    }

    // MARK: - Generic enum↔catalog invariants (foundational; auto-cover future languages)

    /// Every `AppLocale` case must map to exactly one `LanguageDescriptor`, proving a one-to-one
    /// enum↔descriptor relationship that automatically covers any language added later.
    func testEveryAppLocaleHasExactlyOneDescriptor() {
        for locale in AppLocale.allCases {
            let matches = LanguageCatalog.all.filter {
                $0.code == locale.rawValue
            }
            XCTAssertEqual(
                matches.count,
                1,
                "\(locale.rawValue) must have exactly one descriptor, found \(matches.count)"
            )
        }
    }

    /// Re-affirm catalog order generically, expressed directly over `AppLocale.allCases` so a future
    /// language inserted into the enum is held to the same ordering contract.
    func testCatalogOrderMatchesAllCasesGenerically() {
        XCTAssertEqual(LanguageCatalog.all.map(\.code), AppLocale.allCases.map(\.rawValue))
    }

    /// The ODR-tag convention is enforced generically over every case: bundled-base locales carry no
    /// tags, downloadable locales carry exactly `["lang-<code>"]` built from the rawValue. No
    /// hardcoded language list, so any future language is validated automatically.
    func testODRTagsAreGenericallyConsistentOverAllCases() {
        for locale in AppLocale.allCases {
            if locale.isBundledBaseLanguage {
                XCTAssertTrue(
                    locale.odrTags.isEmpty,
                    "\(locale.rawValue) is bundled-base → must carry no ODR tags"
                )
            } else {
                XCTAssertEqual(
                    locale.odrTags,
                    ["lang-\(locale.rawValue)"],
                    "\(locale.rawValue) is downloadable → must carry exactly [lang-\(locale.rawValue)]"
                )
            }
        }
    }

    // MARK: - Descriptor lookup

    func testDescriptorLookupForEveryAppLocale() {
        for locale in AppLocale.allCases {
            let descriptor = LanguageCatalog.descriptor(for: locale)
            XCTAssertEqual(
                descriptor.code,
                locale.rawValue,
                "descriptor(for: \(locale.rawValue)) must return the matching code"
            )
        }
    }

    // MARK: - Display names

    func testDisplayNamesMatchExpectedNativeStrings() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .en).displayName, "English")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .fr).displayName, "Français")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .de).displayName, "Deutsch")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esMX).displayName, "Español (México)")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esES).displayName, "Español (España)")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ca).displayName, "Català")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .eu).displayName, "Euskara")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .yua).displayName, "Màaya t'àan")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .it).displayName, "Italiano")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .pl).displayName, "Polski")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nl).displayName, "Nederlands")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .sr).displayName, "Српски")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ko).displayName, "한국어")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nah).displayName, "Nāhuatl")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ja).displayName, "日本語")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .zhHans).displayName, "简体中文")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .hi).displayName, "हिन्दी")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ar).displayName, "العربية")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .bn).displayName, "বাংলা")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ptBR).displayName, "Português (Brasil)")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ur).displayName, "اردو")
    }

    /// The remaining 6 content-pending languages are COMPLETE-content by contract: each routes
    /// straight to English as an ultimate, never-hit safety net, NOT through es-MX/es-ES. `.ja` has
    /// shipped complete content (story 003) and is asserted separately below.
    func testFallbackChainForContentPendingLanguagesGoStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .zhHans).fallbackChain, [.zhHans, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .hi).fallbackChain, [.hi, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ar).fallbackChain, [.ar, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .bn).fallbackChain, [.bn, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ptBR).fallbackChain, [.ptBR, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ur).fallbackChain, [.ur, .en])
        for locale in [AppLocale.zhHans, .hi, .ar, .bn, .ptBR, .ur] {
            XCTAssertFalse(
                locale.fallsBackThroughSpanish,
                "\(locale.rawValue) is COMPLETE content and must not route through Spanish"
            )
        }
    }

    /// Japanese has shipped COMPLETE content (story 003): it routes straight to English as a never-hit
    /// safety net `[ja, en]`, NOT through es-MX/es-ES, and its catalog identity (display name "日本語",
    /// ODR tag "lang-ja") is unchanged.
    func testFallbackChainForJapaneseGoesStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ja).fallbackChain, [.ja, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ja).displayName, "日本語")
        XCTAssertEqual(AppLocale.ja.odrTags, ["lang-ja"])
        XCTAssertFalse(
            AppLocale.ja.fallsBackThroughSpanish,
            "ja is COMPLETE content and must not route through Spanish"
        )
    }

    // MARK: - Fallback chains

    func testFallbackChainForEnglishIsSelfOnly() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .en).fallbackChain, [.en])
    }

    func testFallbackChainForSpanishBaseEndsInEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esMX).fallbackChain, [.esMX, .en])
    }

    func testFallbackChainForFullyTranslatedLanguagesGoStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .fr).fallbackChain, [.fr, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .de).fallbackChain, [.de, .en])
    }

    /// Italian is a COMPLETE-content language: it routes straight to English as a never-hit safety
    /// net, NOT through es-MX/es-ES like the best-effort languages.
    func testFallbackChainForItalianGoesStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .it).fallbackChain, [.it, .en])
        XCTAssertFalse(
            AppLocale.it.fallsBackThroughSpanish,
            "it is COMPLETE content and must not route through Spanish"
        )
    }

    /// Polish is a COMPLETE-content language: it routes straight to English as a never-hit safety
    /// net, NOT through es-MX/es-ES like the best-effort languages.
    func testFallbackChainForPolishGoesStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .pl).fallbackChain, [.pl, .en])
        XCTAssertFalse(
            AppLocale.pl.fallsBackThroughSpanish,
            "pl is COMPLETE content and must not route through Spanish"
        )
    }

    /// Dutch is a COMPLETE-content language: it routes straight to English as a never-hit safety
    /// net, NOT through es-MX/es-ES like the best-effort languages.
    func testFallbackChainForDutchGoesStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nl).fallbackChain, [.nl, .en])
        XCTAssertFalse(
            AppLocale.nl.fallsBackThroughSpanish,
            "nl is COMPLETE content and must not route through Spanish"
        )
    }

    /// Serbian (Cyrillic) is a COMPLETE-content language: it routes straight to English as a never-hit
    /// safety net, NOT through es-MX/es-ES like the best-effort languages.
    func testFallbackChainForSerbianGoesStraightToEnglish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .sr).fallbackChain, [.sr, .en])
        XCTAssertFalse(
            AppLocale.sr.fallsBackThroughSpanish,
            "sr is COMPLETE content and must not route through Spanish"
        )
    }

    func testFallbackChainForPartialLanguagesRouteThroughSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ko).fallbackChain, [.ko, .esMX, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nah).fallbackChain, [.nah, .esMX, .en])
    }

    /// Spain Spanish resolves through its own pack, then Mexican Spanish, then English.
    func testFallbackChainForSpainSpanishRoutesThroughMexicanSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esES).fallbackChain, [.esES, .esMX, .en])
    }

    /// Catalan (best-effort content) resolves through its own pack, then Spain Spanish, then English.
    func testFallbackChainForCatalanRoutesThroughSpainSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ca).fallbackChain, [.ca, .esES, .en])
    }

    /// Basque (best-effort content) resolves through its own pack, then Spain Spanish, then English.
    func testFallbackChainForBasqueRoutesThroughSpainSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .eu).fallbackChain, [.eu, .esES, .en])
    }

    /// Yucatec Maya (best-effort content) resolves through its own pack, then *Mexican* Spanish
    /// (es-MX, NOT es-ES), then English — matching `fallsBackThroughSpanish`.
    func testFallbackChainForYucatecMayaRoutesThroughMexicanSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .yua).fallbackChain, [.yua, .esMX, .en])
    }

    // MARK: - Availability flag

    func testBundledBaseLanguages() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .en).availability, .bundledBase)
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esMX).availability, .bundledBase)
        XCTAssertTrue(AppLocale.en.isBundledBaseLanguage)
        XCTAssertTrue(AppLocale.esMX.isBundledBaseLanguage)
    }

    func testDownloadablePackLanguages() {
        let downloadable: [AppLocale] = [
            .fr, .de, .esES, .ca, .eu, .yua, .it, .pl, .nl, .sr, .ko, .nah,
            .ja, .zhHans, .hi, .ar, .bn, .ptBR, .ur
        ]
        for locale in downloadable {
            XCTAssertEqual(
                LanguageCatalog.descriptor(for: locale).availability,
                .downloadablePack,
                "\(locale.rawValue) must be a downloadable pack"
            )
            XCTAssertFalse(
                locale.isBundledBaseLanguage,
                "\(locale.rawValue) must not be a bundled base language"
            )
        }
    }

    // MARK: - ODR tag mapping (story 004)

    func testBaseLanguagesHaveNoODRTags() {
        XCTAssertTrue(AppLocale.en.odrTags.isEmpty, "base language en must never carry ODR tags")
        XCTAssertTrue(AppLocale.esMX.odrTags.isEmpty, "base language es-MX must never carry ODR tags")
    }

    func testDownloadableLanguagesYieldExpectedODRTags() {
        XCTAssertEqual(AppLocale.fr.odrTags, ["lang-fr"])
        XCTAssertEqual(AppLocale.de.odrTags, ["lang-de"])
        XCTAssertEqual(AppLocale.esES.odrTags, ["lang-es-ES"])
        XCTAssertEqual(AppLocale.ca.odrTags, ["lang-ca"])
        XCTAssertEqual(AppLocale.eu.odrTags, ["lang-eu"])
        XCTAssertEqual(AppLocale.yua.odrTags, ["lang-yua"])
        XCTAssertEqual(AppLocale.it.odrTags, ["lang-it"])
        XCTAssertEqual(AppLocale.pl.odrTags, ["lang-pl"])
        XCTAssertEqual(AppLocale.nl.odrTags, ["lang-nl"])
        XCTAssertEqual(AppLocale.sr.odrTags, ["lang-sr"])
        XCTAssertEqual(AppLocale.ko.odrTags, ["lang-ko"])
        XCTAssertEqual(AppLocale.nah.odrTags, ["lang-nah"])
        XCTAssertEqual(AppLocale.ja.odrTags, ["lang-ja"])
        XCTAssertEqual(AppLocale.zhHans.odrTags, ["lang-zh-Hans"])
        XCTAssertEqual(AppLocale.hi.odrTags, ["lang-hi"])
        XCTAssertEqual(AppLocale.ar.odrTags, ["lang-ar"])
        XCTAssertEqual(AppLocale.bn.odrTags, ["lang-bn"])
        XCTAssertEqual(AppLocale.ptBR.odrTags, ["lang-pt-BR"])
        XCTAssertEqual(AppLocale.ur.odrTags, ["lang-ur"])
    }

    func testEveryDownloadablePackHasNonEmptyTags_andBaseHasNone() {
        for locale in AppLocale.allCases {
            if locale.isBundledBaseLanguage {
                XCTAssertTrue(locale.odrTags.isEmpty, "\(locale.rawValue) is base → no tags")
            } else {
                XCTAssertFalse(locale.odrTags.isEmpty, "\(locale.rawValue) is downloadable → has a tag")
            }
        }
    }

    // MARK: - AppLocale catalog-backed accessors

    func testAppLocaleFallbackChainMatchesDescriptor() {
        for locale in AppLocale.allCases {
            XCTAssertEqual(locale.fallbackChain, LanguageCatalog.descriptor(for: locale).fallbackChain)
        }
    }
}
