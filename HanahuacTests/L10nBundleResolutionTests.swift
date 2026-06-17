import XCTest
@testable import Hanahuac

/// Exercises `L10n.string(_:locale:)` against the *real shipped `.lproj` bundles* (not stubs), so it
/// proves the Korean/Nahuatl `Localizable.strings` files are bundled and that the
/// selected → Mexican Spanish → English fallback chain resolves at runtime.
final class L10nBundleResolutionTests: XCTestCase {
    /// A key both ko and nah translate → returns the new-language value.
    func testTranslatedKey_resolvesToSelectedLanguage() {
        XCTAssertEqual(L10n.string("settings.language", locale: .ko), "언어")
        XCTAssertEqual(L10n.string("settings.language", locale: .nah), "Tlahtōlli")
    }

    /// Korean fully covers the UI keys, so a key Korean translates resolves to Korean (not Spanish).
    func testKoreanCoversCoreKeys() {
        XCTAssertEqual(L10n.string("home.categories", locale: .ko), "분류")
        XCTAssertEqual(L10n.string("quiz_summary.done", locale: .ko), "완료")
    }

    /// A key Nahuatl does NOT translate falls back to the Mexican Spanish value, never English and
    /// never the raw key.
    func testNahuatl_missingKey_fallsBackToMexicanSpanish() {
        let nah = L10n.string("settings.sync.toggle", locale: .nah)
        let esMX = L10n.string("settings.sync.toggle", locale: .esMX)
        let en = L10n.string("settings.sync.toggle", locale: .en)

        XCTAssertEqual(nah, esMX, "Untranslated Nahuatl key should serve the Mexican Spanish value")
        XCTAssertNotEqual(nah, en, "Should not fall through to English while Spanish exists")
        XCTAssertNotEqual(nah, "settings.sync.toggle", "Must never surface the raw key")
    }

    /// A completely unknown key returns the key itself (Apple's contract) rather than crashing.
    func testUnknownKey_returnsKey() {
        XCTAssertEqual(L10n.string("__no_such_key__", locale: .ko), "__no_such_key__")
    }
}
