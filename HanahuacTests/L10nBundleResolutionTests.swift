import XCTest
@testable import Hanahuac

/// Validates the non-base languages' shipped `Localizable.strings` content and the runtime fallback
/// behavior now that ko/nah ship as On-Demand Resources (`lang-ko`/`lang-nah`, story 006).
///
/// Two layers:
/// - Content: read each pack's `.lproj` directly from its built asset pack (``ODRTestSupport``) and
///   assert the real translated values are present and correct. Skips if the asset pack is not
///   reachable in the current environment (the simulator unit-test host has no asset-pack server, so
///   ODR cannot be mounted into `Bundle.main` here).
/// - Offline fallback: with NO pack downloaded, `L10n.string(_:locale:)` for a non-base locale
///   degrades through the chain (ko → es-MX → en; nah → es-MX → en) and never surfaces the raw key —
///   the base-only offline path the app relies on.
final class L10nBundleResolutionTests: XCTestCase {
    // MARK: - Shipped pack content (read directly from the asset pack)

    /// A key both ko and nah translate carries the new-language value in the shipped pack.
    func testTranslatedKey_shippedInPack() throws {
        let ko = try ODRTestSupport.lprojBundle(for: .ko)
        let nah = try ODRTestSupport.lprojBundle(for: .nah)
        XCTAssertEqual(ko.localizedString(forKey: "settings.language", value: nil, table: nil), "언어")
        XCTAssertEqual(
            nah.localizedString(forKey: "settings.language", value: nil, table: nil),
            "Tlahtōlli"
        )
    }

    /// Korean fully covers the core UI keys in its shipped pack.
    func testKoreanCoversCoreKeys() throws {
        let ko = try ODRTestSupport.lprojBundle(for: .ko)
        XCTAssertEqual(ko.localizedString(forKey: "home.categories", value: nil, table: nil), "분류")
        XCTAssertEqual(ko.localizedString(forKey: "quiz_summary.done", value: nil, table: nil), "완료")
    }

    // MARK: - Offline fallback (no pack downloaded)

    /// With no pack downloaded, a non-base locale resolves through its fallback chain to a bundled
    /// base language, never the raw key. (ko/nah → es-MX → en.)
    func testOfflineFallback_resolvesThroughChain() {
        let ko = L10n.string("settings.language", locale: .ko)
        let nah = L10n.string("settings.language", locale: .nah)
        let esMX = L10n.string("settings.language", locale: .esMX)
        XCTAssertEqual(ko, esMX, "Without the ko pack, ko resolves the es-MX base value")
        XCTAssertEqual(nah, esMX, "Without the nah pack, nah resolves the es-MX base value")
        XCTAssertNotEqual(ko, "settings.language", "Must never surface the raw key")
    }

    /// A key Nahuatl does NOT translate falls back to the Mexican Spanish value, never English and
    /// never the raw key — holds whether or not the pack is present, since the chain routes through
    /// es-MX before en.
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
