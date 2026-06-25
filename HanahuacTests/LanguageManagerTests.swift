import XCTest
@testable import Hanahuac

/// Tests `LanguageManager` persistence to/from `UserDefaults`.
///
/// Note: `LanguageManager` is a singleton (`shared`), so tests use a fresh
/// `UserDefaults` suite to avoid cross-test pollution.
final class LanguageManagerTests: XCTestCase {
    private let key = "appLocale"

    override func tearDown() {
        // Clean up after each test so state does not leak between runs.
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    // MARK: - Setting current writes to UserDefaults

    func testSettingCurrent_writesToUserDefaults() {
        UserDefaults.standard.removeObject(forKey: key)
        let manager = LanguageManager.shared

        manager.current = .fr
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: key),
            "fr",
            "Setting current to .fr should persist 'fr' to UserDefaults"
        )

        manager.current = .de
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: key),
            "de",
            "Setting current to .de should persist 'de' to UserDefaults"
        )

        manager.current = .esMX
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: key),
            "es-MX",
            "Setting current to .esMX should persist 'es-MX' to UserDefaults"
        )

        manager.current = .en
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: key),
            "en",
            "Setting current to .en should persist 'en' to UserDefaults"
        )
    }

    // MARK: - Reading back the persisted value

    func testSettingCurrent_isReadableBack() {
        let manager = LanguageManager.shared

        manager.current = .fr
        XCTAssertEqual(manager.current, .fr)

        manager.current = .de
        XCTAssertEqual(manager.current, .de)

        manager.current = .esMX
        XCTAssertEqual(manager.current, .esMX)

        manager.current = .en
        XCTAssertEqual(manager.current, .en)
    }

    // MARK: - Persisted UserDefaults value is respected on next read

    /// Simulates what happens when a saved value exists in UserDefaults:
    /// the saved raw value should round-trip through `AppLocale(rawValue:)`.
    func testSavedUserDefaults_frenchRawValue_resolvesToFr() {
        UserDefaults.standard.set("fr", forKey: key)
        let restored = AppLocale(rawValue: UserDefaults.standard.string(forKey: key) ?? "")
        XCTAssertEqual(
            restored,
            .fr,
            "Raw value 'fr' stored in UserDefaults should restore to .fr"
        )
    }

    func testSavedUserDefaults_germanRawValue_resolvesToDe() {
        UserDefaults.standard.set("de", forKey: key)
        let restored = AppLocale(rawValue: UserDefaults.standard.string(forKey: key) ?? "")
        XCTAssertEqual(
            restored,
            .de,
            "Raw value 'de' stored in UserDefaults should restore to .de"
        )
    }

    func testSavedUserDefaults_spanishRawValue_resolvesToEsMX() {
        UserDefaults.standard.set("es-MX", forKey: key)
        let restored = AppLocale(rawValue: UserDefaults.standard.string(forKey: key) ?? "")
        XCTAssertEqual(
            restored,
            .esMX,
            "Raw value 'es-MX' stored in UserDefaults should restore to .esMX"
        )
    }

    func testSavedUserDefaults_englishRawValue_resolvesToEn() {
        UserDefaults.standard.set("en", forKey: key)
        let restored = AppLocale(rawValue: UserDefaults.standard.string(forKey: key) ?? "")
        XCTAssertEqual(
            restored,
            .en,
            "Raw value 'en' stored in UserDefaults should restore to .en"
        )
    }

    func testSavedUserDefaults_unknownRawValue_resolvesToNil() {
        UserDefaults.standard.set("xx", forKey: key)
        let restored = AppLocale(rawValue: UserDefaults.standard.string(forKey: key) ?? "")
        XCTAssertNil(
            restored,
            "Unknown raw value 'xx' must not resolve to any AppLocale (returns nil)"
        )
    }

    // MARK: - LanguageManager.shared reflects current locale in memory

    func testSharedManager_currentLocaleIsAValidAppLocale() {
        let manager = LanguageManager.shared
        XCTAssertNotNil(manager.current)
        XCTAssertTrue(
            AppLocale.allCases.contains(manager.current),
            "LanguageManager.current must always be a valid AppLocale case"
        )
    }

    func testSharedManager_setAndGet_allLocales() {
        let manager = LanguageManager.shared
        for locale in AppLocale.allCases {
            manager.current = locale
            XCTAssertEqual(
                manager.current,
                locale,
                "After setting current to \(locale), reading back should return \(locale)"
            )
        }
    }
}
