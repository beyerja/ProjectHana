import XCTest
@testable import Hanahuac

/// Tests the data-driven ``LanguageCatalog`` and ``LanguageDescriptor`` that back ``AppLocale``'s
/// display names, fallback chains, and bundled/downloadable availability flag.
final class LanguageCatalogTests: XCTestCase {
    // MARK: - Catalog shape

    func testCatalogContainsExactlySixLanguages() {
        XCTAssertEqual(LanguageCatalog.all.count, 6)
    }

    /// Catalog ordering must match `AppLocale.allCases` so the picker order is preserved.
    func testCatalogOrderMatchesAllCases() {
        let catalogCodes = LanguageCatalog.all.map(\.code)
        let appLocaleCodes = AppLocale.allCases.map(\.rawValue)
        XCTAssertEqual(catalogCodes, appLocaleCodes)
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
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ko).displayName, "한국어")
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nah).displayName, "Nāhuatl")
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

    func testFallbackChainForPartialLanguagesRouteThroughSpanish() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .ko).fallbackChain, [.ko, .esMX, .en])
        XCTAssertEqual(LanguageCatalog.descriptor(for: .nah).fallbackChain, [.nah, .esMX, .en])
    }

    // MARK: - Availability flag

    func testBundledBaseLanguages() {
        XCTAssertEqual(LanguageCatalog.descriptor(for: .en).availability, .bundledBase)
        XCTAssertEqual(LanguageCatalog.descriptor(for: .esMX).availability, .bundledBase)
        XCTAssertTrue(AppLocale.en.isBundledBaseLanguage)
        XCTAssertTrue(AppLocale.esMX.isBundledBaseLanguage)
    }

    func testDownloadablePackLanguages() {
        for locale in [AppLocale.fr, .de, .ko, .nah] {
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

    // MARK: - AppLocale catalog-backed accessors

    func testAppLocaleFallbackChainMatchesDescriptor() {
        for locale in AppLocale.allCases {
            XCTAssertEqual(locale.fallbackChain, LanguageCatalog.descriptor(for: locale).fallbackChain)
        }
    }
}
