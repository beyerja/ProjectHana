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

    /// Any es-* locale resolves to .esMX (acceptance criteria).
    func testMatchingSpanishVariants() {
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-MX")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-ES")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es-AR")), .esMX)
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es")), .esMX)
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
        XCTAssertEqual(AppLocale.ko.id, "ko")
        XCTAssertEqual(AppLocale.nah.id, "nah")
    }

    func testAllCasesCount() {
        XCTAssertEqual(AppLocale.allCases.count, 6)
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
