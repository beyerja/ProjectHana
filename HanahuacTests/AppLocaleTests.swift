import XCTest
@testable import Hanahuac

final class AppLocaleTests: XCTestCase {
    // MARK: - AppLocale.matching

    func testMatchingEnglish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "en")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "en-US")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "en-GB")), .en)
    }

    func testMatchingFrench() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "fr")), .fr)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "fr-FR")), .fr)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "fr-CA")), .fr)
    }

    func testMatchingGerman() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "de")), .de)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "de-DE")), .de)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "de-AT")), .de)
    }

    /// Any es-* locale resolves to .esMX (acceptance criteria). Even though `.esES` now exists as a
    /// distinct, picker-selectable language, a Spain-region device locale (`es_ES`/`es-ES`) must NEVER
    /// auto-select it — every es-* locale keeps defaulting to Mexican Spanish.
    func testMatchingSpanishVariants() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-AR")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es")), .esMX)
    }

    /// Catalan auto-detects its own device locale via the catalog code-lookup path (code `ca` ==
    /// rawValue), without perturbing the es-* → es-MX mapping. This is the regression guard required by
    /// the story: a `ca` device locale selects Catalan while every es-* device locale still defaults to
    /// Mexican Spanish.
    func testMatchingCatalanDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ca")), .ca)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ca-ES")), .ca)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ca_ES")), .ca)
        // es-* mapping is unperturbed by adding Catalan.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
    }

    /// Basque auto-detects its own device locale via the catalog code-lookup path (code `eu` ==
    /// rawValue), without perturbing the es-* → es-MX mapping. Regression guard required by the story:
    /// an `eu` device locale selects Basque while every es-* device locale still defaults to Mexican
    /// Spanish.
    func testMatchingBasqueDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "eu")), .eu)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "eu-ES")), .eu)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "eu_ES")), .eu)
        // es-* mapping is unperturbed by adding Basque.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
    }

    /// Yucatec Maya auto-detects its own device locale via the catalog code-lookup path (code `yua` ==
    /// rawValue), without perturbing the es-* → es-MX mapping. Regression guard required by the story:
    /// a `yua` device locale selects Yucatec Maya while every es-* device locale still defaults to
    /// Mexican Spanish.
    func testMatchingYucatecMayaDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "yua")), .yua)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "yua-MX")), .yua)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "yua_MX")), .yua)
        // es-* mapping is unperturbed by adding Yucatec Maya.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
    }

    /// Italian auto-detects its own device locale via the catalog code-lookup path (code `it` ==
    /// rawValue), without perturbing the es-* → es-MX mapping. Regression guard required by the story:
    /// an `it` device locale selects Italian while every es-* device locale still defaults to Mexican
    /// Spanish.
    func testMatchingItalianDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "it")), .it)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "it-IT")), .it)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "it_IT")), .it)
        // es-* mapping is unperturbed by adding Italian.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
    }

    /// Polish auto-detects its own device locale via the catalog code-lookup path (code `pl` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingPolishDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pl")), .pl)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pl-PL")), .pl)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pl_PL")), .pl)
        // es-* mapping is unperturbed by adding Polish.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
    }

    /// Dutch auto-detects its own device locale via the catalog code-lookup path (code `nl` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingDutchDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nl")), .nl)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nl-NL")), .nl)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nl_NL")), .nl)
        // es-* mapping is unperturbed by adding Dutch.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-419")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
    }

    /// Serbian (Cyrillic) auto-detects its own device locale via the catalog code-lookup path
    /// (code `sr` == rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingSerbianDoesNotPerturbSpanish() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "sr")), .sr)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "sr-RS")), .sr)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "sr_RS")), .sr)
        // es-* mapping is unperturbed by adding Serbian.
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-419")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
    }

    func testMatchingKorean() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ko")), .ko)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ko-KR")), .ko)
    }

    /// Generic Nahuatl: the macrolanguage code and common individual ISO 639-3 variants map to .nah.
    func testMatchingNahuatl() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nah")), .nah)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nhn")), .nah)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "nch")), .nah)
    }

    /// Japanese auto-detects its own device locale via the catalog code-lookup path (code `ja` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingJapanese() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ja")), .ja)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ja-JP")), .ja)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ja_JP")), .ja)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Any Chinese variant (generic `zh`, `zh-Hans`, `zh-Hant`, `zh-CN`) resolves to Simplified
    /// Chinese, mirroring the es-* → es-MX collapse, without perturbing the es-* mapping.
    func testMatchingChineseVariants() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh")), .zhHans)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh-Hans")), .zhHans)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh-Hant")), .zhHans)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh-CN")), .zhHans)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh_TW")), .zhHans)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Hindi auto-detects its own device locale via the catalog code-lookup path (code `hi` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingHindi() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "hi")), .hi)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "hi-IN")), .hi)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Arabic auto-detects its own device locale via the catalog code-lookup path (code `ar` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingArabic() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ar")), .ar)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ar-EG")), .ar)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ar_SA")), .ar)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Bengali auto-detects its own device locale via the catalog code-lookup path (code `bn` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingBengali() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "bn")), .bn)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "bn-BD")), .bn)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Any Portuguese variant (generic `pt`, `pt-BR`, `pt-PT`) resolves to Brazilian Portuguese,
    /// mirroring the es-* → es-MX collapse, without perturbing the es-* mapping.
    func testMatchingPortugueseVariants() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pt")), .ptBR)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pt-BR")), .ptBR)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pt-PT")), .ptBR)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "pt_PT")), .ptBR)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Urdu auto-detects its own device locale via the catalog code-lookup path (code `ur` ==
    /// rawValue), without perturbing the es-* → es-MX mapping.
    func testMatchingUrdu() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ur")), .ur)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ur-PK")), .ur)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es_ES")), .esMX)
    }

    /// Genuinely-unmapped locales fall back to .en (acceptance criteria).
    func testMatchingUnrecognizedLocale() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "xx")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zz-ZZ")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ru")), .en)
    }

    // MARK: - AppLocale properties

    func testIdentifiable() {
        XCTAssertEqual(AppLocale.en.id, "en")
        XCTAssertEqual(AppLocale.fr.id, "fr")
        XCTAssertEqual(AppLocale.de.id, "de")
        XCTAssertEqual(AppLocale.esMX.id, "es-MX")
        XCTAssertEqual(AppLocale.esES.id, "es-ES")
        XCTAssertEqual(AppLocale.ca.id, "ca")
        XCTAssertEqual(AppLocale.eu.id, "eu")
        XCTAssertEqual(AppLocale.yua.id, "yua")
        XCTAssertEqual(AppLocale.it.id, "it")
        XCTAssertEqual(AppLocale.pl.id, "pl")
        XCTAssertEqual(AppLocale.nl.id, "nl")
        XCTAssertEqual(AppLocale.sr.id, "sr")
        XCTAssertEqual(AppLocale.ko.id, "ko")
        XCTAssertEqual(AppLocale.nah.id, "nah")
        XCTAssertEqual(AppLocale.ja.id, "ja")
        XCTAssertEqual(AppLocale.zhHans.id, "zh-Hans")
        XCTAssertEqual(AppLocale.hi.id, "hi")
        XCTAssertEqual(AppLocale.ar.id, "ar")
        XCTAssertEqual(AppLocale.bn.id, "bn")
        XCTAssertEqual(AppLocale.ptBR.id, "pt-BR")
        XCTAssertEqual(AppLocale.ur.id, "ur")
    }

    func testAllCasesCount() {
        XCTAssertEqual(AppLocale.allCases.count, 21)
    }

    /// The remaining 2 content-pending languages are enumerated in the picker with their native-script
    /// display names and their candidate chain goes straight to English (COMPLETE-content by contract).
    /// `.ja` (story 003), `.zhHans` (story 004), `.hi` (story 005), `.bn` (story 006) and `.ptBR`
    /// (story 007) have shipped complete content and are asserted separately below.
    func testContentPendingLanguagesEnumeratedWithNativeDisplayNames() {
        XCTAssertEqual(AppLocale.ar.displayName, "العربية")
        XCTAssertEqual(AppLocale.ur.displayName, "اردو")
        for locale in [AppLocale.ar, .ur] {
            XCTAssertEqual(
                L10n.bundleCandidates(for: locale),
                [locale.rawValue, "en"],
                "\(locale.rawValue) is COMPLETE content → straight to English"
            )
            XCTAssertFalse(
                locale.fallsBackThroughSpanish,
                "\(locale.rawValue) must not route through Spanish"
            )
        }
    }

    /// Japanese has shipped COMPLETE content (story 003): it is enumerated in the picker with its
    /// native display name "日本語", its bundle-candidate chain goes straight to English `[ja, en]`
    /// (en is a never-hit safety net), and it never routes through Spanish.
    func testJapaneseEnumeratedAsCompleteContentLanguage() {
        XCTAssertEqual(AppLocale.ja.displayName, "日本語")
        XCTAssertEqual(
            L10n.bundleCandidates(for: .ja),
            ["ja", "en"],
            "ja is COMPLETE content → straight to English"
        )
        XCTAssertFalse(
            AppLocale.ja.fallsBackThroughSpanish,
            "ja is COMPLETE content and must not route through Spanish"
        )
    }

    /// Simplified Chinese has shipped COMPLETE content (story 004): it is enumerated in the picker
    /// with its native display name "简体中文", its bundle-candidate chain goes straight to English
    /// `[zh-Hans, en]` (en is a never-hit safety net), and it never routes through Spanish.
    func testSimplifiedChineseEnumeratedAsCompleteContentLanguage() {
        XCTAssertEqual(AppLocale.zhHans.displayName, "简体中文")
        XCTAssertEqual(
            L10n.bundleCandidates(for: .zhHans),
            ["zh-Hans", "en"],
            "zh-Hans is COMPLETE content → straight to English"
        )
        XCTAssertFalse(
            AppLocale.zhHans.fallsBackThroughSpanish,
            "zh-Hans is COMPLETE content and must not route through Spanish"
        )
    }

    /// Hindi has shipped COMPLETE content (story 005): it is enumerated in the picker with its native
    /// display name "हिन्दी", its bundle-candidate chain goes straight to English `[hi, en]` (en is a
    /// never-hit safety net), and it never routes through Spanish.
    func testHindiEnumeratedAsCompleteContentLanguage() {
        XCTAssertEqual(AppLocale.hi.displayName, "हिन्दी")
        XCTAssertEqual(
            L10n.bundleCandidates(for: .hi),
            ["hi", "en"],
            "hi is COMPLETE content → straight to English"
        )
        XCTAssertFalse(
            AppLocale.hi.fallsBackThroughSpanish,
            "hi is COMPLETE content and must not route through Spanish"
        )
    }

    /// Bengali has shipped COMPLETE content (story 006): it is enumerated in the picker with its native
    /// display name "বাংলা", its bundle-candidate chain goes straight to English `[bn, en]` (en is a
    /// never-hit safety net), and it never routes through Spanish.
    func testBengaliEnumeratedAsCompleteContentLanguage() {
        XCTAssertEqual(AppLocale.bn.displayName, "বাংলা")
        XCTAssertEqual(
            L10n.bundleCandidates(for: .bn),
            ["bn", "en"],
            "bn is COMPLETE content → straight to English"
        )
        XCTAssertFalse(
            AppLocale.bn.fallsBackThroughSpanish,
            "bn is COMPLETE content and must not route through Spanish"
        )
    }

    /// Brazilian Portuguese has shipped COMPLETE content (story 007): it is enumerated in the picker
    /// with its native display name "Português (Brasil)", its bundle-candidate chain goes straight to
    /// English `[pt-BR, en]` (en is a never-hit safety net), and it never routes through Spanish.
    func testBrazilianPortugueseEnumeratedAsCompleteContentLanguage() {
        XCTAssertEqual(AppLocale.ptBR.displayName, "Português (Brasil)")
        XCTAssertEqual(
            L10n.bundleCandidates(for: .ptBR),
            ["pt-BR", "en"],
            "pt-BR is COMPLETE content → straight to English"
        )
        XCTAssertFalse(
            AppLocale.ptBR.fallsBackThroughSpanish,
            "pt-BR is COMPLETE content and must not route through Spanish"
        )
    }

    /// es-ES is enumerated in the picker with its native display name "Español (España)" and sits
    /// immediately after es-MX, matching the catalog order.
    func testSpainSpanishEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.esES))
        XCTAssertEqual(AppLocale.esES.displayName, "Español (España)")
        let codes = AppLocale.allCases.map(\.rawValue)
        let mxIndex = try XCTUnwrap(codes.firstIndex(of: "es-MX"))
        let esIndex = try XCTUnwrap(codes.firstIndex(of: "es-ES"))
        XCTAssertEqual(esIndex, mxIndex + 1, "es-ES must immediately follow es-MX")
    }

    /// Catalan is enumerated in the picker with its native display name "Català" and sits immediately
    /// after es-ES, matching the catalog order.
    func testCatalanEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.ca))
        XCTAssertEqual(AppLocale.ca.displayName, "Català")
        let codes = AppLocale.allCases.map(\.rawValue)
        let esIndex = try XCTUnwrap(codes.firstIndex(of: "es-ES"))
        let caIndex = try XCTUnwrap(codes.firstIndex(of: "ca"))
        XCTAssertEqual(caIndex, esIndex + 1, "ca must immediately follow es-ES")
    }

    /// Basque is enumerated in the picker with its native display name "Euskara" and sits immediately
    /// after ca, matching the catalog order.
    func testBasqueEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.eu))
        XCTAssertEqual(AppLocale.eu.displayName, "Euskara")
        let codes = AppLocale.allCases.map(\.rawValue)
        let caIndex = try XCTUnwrap(codes.firstIndex(of: "ca"))
        let euIndex = try XCTUnwrap(codes.firstIndex(of: "eu"))
        XCTAssertEqual(euIndex, caIndex + 1, "eu must immediately follow ca")
    }

    /// Yucatec Maya is enumerated in the picker with its native display name "Màaya t'àan" (graves and
    /// glottal apostrophe preserved exactly) and sits immediately after eu, matching the catalog order.
    func testYucatecMayaEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.yua))
        XCTAssertEqual(AppLocale.yua.displayName, "Màaya t'àan")
        let codes = AppLocale.allCases.map(\.rawValue)
        let euIndex = try XCTUnwrap(codes.firstIndex(of: "eu"))
        let yuaIndex = try XCTUnwrap(codes.firstIndex(of: "yua"))
        XCTAssertEqual(yuaIndex, euIndex + 1, "yua must immediately follow eu")
    }

    /// Italian is enumerated in the picker with its native display name "Italiano" and sits immediately
    /// after yua, matching the catalog order.
    func testItalianEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.it))
        XCTAssertEqual(AppLocale.it.displayName, "Italiano")
        let codes = AppLocale.allCases.map(\.rawValue)
        let yuaIndex = try XCTUnwrap(codes.firstIndex(of: "yua"))
        let itIndex = try XCTUnwrap(codes.firstIndex(of: "it"))
        XCTAssertEqual(itIndex, yuaIndex + 1, "it must immediately follow yua")
    }

    /// Italian is COMPLETE content, so its UI-string candidate chain goes straight to English with no
    /// Spanish hop.
    func testBundleCandidatesForItalianGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .it), ["it", "en"])
    }

    /// Polish is enumerated in the picker with its native display name "Polski" and sits immediately
    /// after it, matching the catalog order.
    func testPolishEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.pl))
        XCTAssertEqual(AppLocale.pl.displayName, "Polski")
        let codes = AppLocale.allCases.map(\.rawValue)
        let itIndex = try XCTUnwrap(codes.firstIndex(of: "it"))
        let plIndex = try XCTUnwrap(codes.firstIndex(of: "pl"))
        XCTAssertEqual(plIndex, itIndex + 1, "pl must immediately follow it")
    }

    /// Polish is COMPLETE content, so its UI-string candidate chain goes straight to English with no
    /// Spanish hop.
    func testBundleCandidatesForPolishGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .pl), ["pl", "en"])
    }

    /// Dutch is enumerated in the picker with its native display name "Nederlands" and sits immediately
    /// after pl, matching the catalog order.
    func testDutchEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.nl))
        XCTAssertEqual(AppLocale.nl.displayName, "Nederlands")
        let codes = AppLocale.allCases.map(\.rawValue)
        let plIndex = try XCTUnwrap(codes.firstIndex(of: "pl"))
        let nlIndex = try XCTUnwrap(codes.firstIndex(of: "nl"))
        XCTAssertEqual(nlIndex, plIndex + 1, "nl must immediately follow pl")
    }

    /// Dutch is COMPLETE content, so its UI-string candidate chain goes straight to English with no
    /// Spanish hop.
    func testBundleCandidatesForDutchGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .nl), ["nl", "en"])
    }

    /// Serbian (Cyrillic) is enumerated in the picker with its native display name "Српски" and sits
    /// immediately after nl and immediately before ko, matching the catalog order.
    func testSerbianEnumeratedWithNativeDisplayName() throws {
        XCTAssertTrue(AppLocale.allCases.contains(.sr))
        XCTAssertEqual(AppLocale.sr.displayName, "Српски")
        let codes = AppLocale.allCases.map(\.rawValue)
        let nlIndex = try XCTUnwrap(codes.firstIndex(of: "nl"))
        let srIndex = try XCTUnwrap(codes.firstIndex(of: "sr"))
        let koIndex = try XCTUnwrap(codes.firstIndex(of: "ko"))
        XCTAssertEqual(srIndex, nlIndex + 1, "sr must immediately follow nl")
        XCTAssertEqual(koIndex, srIndex + 1, "sr must immediately precede ko")
    }

    /// Serbian is COMPLETE content, so its UI-string candidate chain goes straight to English with no
    /// Spanish hop.
    func testBundleCandidatesForSerbianGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .sr), ["sr", "en"])
    }

    /// The picker is driven by `allCases`, so the two new languages must be enumerated with their
    /// native-script display names.
    func testNewLanguagesEnumeratedWithNativeDisplayNames() {
        XCTAssertTrue(AppLocale.allCases.contains(.ko))
        XCTAssertTrue(AppLocale.allCases.contains(.nah))
        XCTAssertEqual(AppLocale.ko.displayName, "한국어")
        XCTAssertEqual(AppLocale.nah.displayName, "Nāhuatl")
    }

    func testDisplayNamesNonEmpty() {
        for locale in AppLocale.allCases {
            XCTAssertFalse(locale.displayName.isEmpty, "\(locale.rawValue) displayName must not be empty")
        }
    }

    // MARK: - Fallback chain (selected → es-MX → en)

    func testKoAndNahFallBackThroughSpanish() {
        XCTAssertTrue(AppLocale.ko.fallsBackThroughSpanish)
        XCTAssertTrue(AppLocale.nah.fallsBackThroughSpanish)
        for locale in [AppLocale.en, .fr, .de, .esMX] {
            XCTAssertFalse(locale.fallsBackThroughSpanish, "\(locale.rawValue) must not route through es-MX")
        }
    }

    func testBundleCandidatesForKoAndNahGoThroughSpanishThenEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .ko), ["ko", "es-MX", "en"])
        XCTAssertEqual(L10n.bundleCandidates(for: .nah), ["nah", "es-MX", "en"])
    }

    /// es-ES resolves UI strings through its own pack, then Mexican Spanish, then English.
    func testBundleCandidatesForSpainSpanishGoThroughMexicanSpanishThenEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .esES), ["es-ES", "es-MX", "en"])
        XCTAssertTrue(AppLocale.esES.fallsBackThroughSpanish)
    }

    /// Catalan resolves UI strings through its own pack, then Spain Spanish, then English.
    ///
    /// Note on `fallsBackThroughSpanish`: that property tracks the *Mexican* Spanish (`es-MX`) route
    /// used by ko/nah/es-ES, so it is `false` for `ca` even though `ca` DOES route through Spanish —
    /// its intermediate Spanish target is `es-ES`, which is exactly what the bundle-candidate chain
    /// encodes (`["ca", "es-ES", "en"]`). We assert the chain (the real fallback contract) directly.
    func testBundleCandidatesForCatalanGoThroughSpainSpanishThenEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .ca), ["ca", "es-ES", "en"])
        XCTAssertFalse(
            AppLocale.ca.fallsBackThroughSpanish,
            "ca routes through es-ES, not the es-MX that fallsBackThroughSpanish tracks"
        )
    }

    /// Basque resolves UI strings through its own pack, then Spain Spanish, then English.
    func testBundleCandidatesForBasqueGoThroughSpainSpanishThenEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .eu), ["eu", "es-ES", "en"])
        XCTAssertFalse(
            AppLocale.eu.fallsBackThroughSpanish,
            "eu routes through es-ES, not the es-MX that fallsBackThroughSpanish tracks"
        )
    }

    /// Yucatec Maya (best-effort content) resolves UI strings through its own pack, then *Mexican*
    /// Spanish (es-MX, NOT es-ES), then English — so unlike ca/eu it DOES route through the es-MX that
    /// `fallsBackThroughSpanish` tracks.
    func testBundleCandidatesForYucatecMayaGoThroughMexicanSpanishThenEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .yua), ["yua", "es-MX", "en"])
        XCTAssertTrue(
            AppLocale.yua.fallsBackThroughSpanish,
            "yua routes through es-MX, the route fallsBackThroughSpanish tracks"
        )
    }

    func testBundleCandidatesForEstablishedLocalesEndInEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .fr), ["fr", "en"])
        XCTAssertEqual(L10n.bundleCandidates(for: .de), ["de", "en"])
        XCTAssertEqual(L10n.bundleCandidates(for: .esMX), ["es-MX", "en"])
        XCTAssertEqual(L10n.bundleCandidates(for: .en), ["en", "en"])
    }

    // MARK: - LanguageManager persistence

    func testLanguageManagerPersistence() {
        let key = "appLocale"
        // Reset state
        UserDefaults.standard.removeObject(forKey: key)

        let manager = LanguageManager.shared
        manager.current = .fr
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "fr")

        manager.current = .de
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "de")

        // Restore original so we don't pollute other tests
        UserDefaults.standard.removeObject(forKey: key)
    }
}
