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

    /// Unrecognized locales fall back to .en (acceptance criteria).
    func testMatchingUnrecognizedLocale() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ja")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "zh-Hans")), .en)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "ar")), .en)
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
        XCTAssertEqual(AppLocale.ko.id, "ko")
        XCTAssertEqual(AppLocale.nah.id, "nah")
    }

    func testAllCasesCount() {
        XCTAssertEqual(AppLocale.allCases.count, 13)
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
        let koIndex = try XCTUnwrap(codes.firstIndex(of: "ko"))
        XCTAssertEqual(nlIndex, plIndex + 1, "nl must immediately follow pl")
        XCTAssertEqual(koIndex, nlIndex + 1, "nl must immediately precede ko")
    }

    /// Dutch is COMPLETE content, so its UI-string candidate chain goes straight to English with no
    /// Spanish hop.
    func testBundleCandidatesForDutchGoStraightToEnglish() {
        XCTAssertEqual(L10n.bundleCandidates(for: .nl), ["nl", "en"])
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
