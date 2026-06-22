import XCTest
@testable import Hanahuac

/// Runtime complement to the static `scripts/check-l10n-completeness.py` gate: asserts that every
/// canonical localization key resolves — through the always-resolvable fallback chain — to a real,
/// non-key, non-empty value for ALL `AppLocale` cases.
///
/// The canonical key list is DRIVEN FROM THE EN BASE BUNDLE (read at runtime), so any key added to
/// `en.lproj/Localizable.strings` is automatically covered without editing this test. en and the
/// es-MX base ship in the app bundle and together cover every key, so the chain (selected → es-MX →
/// en) always resolves even for downloadable locales whose pack is not embedded in a clean CI host.
///
/// This guards the same property as `QuizAccessibilityStringsTests` (no raw key ever surfaces) but
/// across the FULL key set rather than only the `a11y.*` subset.
final class L10nCompletenessTests: XCTestCase {
    /// Every key defined in the en base `Localizable.strings`, read directly from the bundled file so
    /// the list tracks the source of truth automatically.
    private func canonicalKeys() throws -> [String] {
        let bundle = L10n.bundle(for: .en)
        let url = try XCTUnwrap(
            bundle.url(forResource: "Localizable", withExtension: "strings"),
            "en Localizable.strings must exist in the en base bundle"
        )
        let dict = try XCTUnwrap(
            NSDictionary(contentsOf: url) as? [String: String],
            "en Localizable.strings must parse as a key/value plist"
        )
        XCTAssertFalse(dict.isEmpty, "en base must define at least one key")
        return Array(dict.keys)
    }

    /// Every canonical key resolves to a non-key, non-empty value for every locale via the chain.
    func testEveryCanonicalKeyResolvesForAllLocales() throws {
        let keys = try canonicalKeys()
        for locale in AppLocale.allCases {
            for key in keys {
                let resolved = L10n.string(key, locale: locale)
                XCTAssertNotEqual(
                    resolved, key,
                    "Key \(key) surfaced the raw key for locale \(locale.rawValue)."
                )
                XCTAssertFalse(
                    resolved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Key \(key) resolved to an empty string for locale \(locale.rawValue)."
                )
            }
        }
    }

    /// Documents and enforces the nah partial-translation convention: a key Nahuatl does NOT define
    /// resolves through nah → es-MX → en to a real value and never the raw key. Missing nah keys that
    /// resolve via this fallback are INTENTIONAL and acceptable — nah is a deliberate partial subset.
    func testNahuatlPartial_untranslatedKeyResolvesViaFallback() {
        // `stats.by_mode` is one of the many keys nah deliberately leaves untranslated (it is
        // app-specific jargon); it must still resolve via the fallback chain, not surface the key.
        let key = "stats.by_mode"
        let nah = L10n.string(key, locale: .nah)
        XCTAssertNotEqual(nah, key, "Untranslated nah key must resolve via nah → es-MX → en fallback")
        XCTAssertFalse(
            nah.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "Fallback value for an untranslated nah key must be non-empty"
        )
    }
}
