import XCTest
@testable import ProjectHana

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
        XCTAssertEqual(AppLocale.matching(Locale(identifier: "es")),    .esMX)
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
    }

    func testAllCasesCount() {
        XCTAssertEqual(AppLocale.allCases.count, 4)
    }

    func testDisplayNamesNonEmpty() {
        for locale in AppLocale.allCases {
            XCTAssertFalse(locale.displayName.isEmpty, "\(locale.rawValue) displayName must not be empty")
        }
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
