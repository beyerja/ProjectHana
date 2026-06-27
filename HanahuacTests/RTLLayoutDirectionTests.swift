import SwiftUI
import XCTest
@testable import Hanahuac

/// Unit coverage for the greenfield RTL infrastructure (story 008): the language-driven RTL signal,
/// its mapping onto SwiftUI's `LayoutDirection`, and the launch-time force-RTL override that lets
/// tests / the walkthrough exercise RTL before ar/ur content exists.
///
/// These assertions are language-agnostic infrastructure tests: they prove RTL is applied for the
/// RTL languages and NOT for LTR languages (the LTR regression guard), independently of whether
/// ar/ur translations have shipped.
final class RTLLayoutDirectionTests: XCTestCase {
    // MARK: - isRTL (catalog-driven RTL set)

    /// Arabic and Urdu are the only RTL languages; their `isRTL` is true.
    func testArabicAndUrduAreRTL() {
        XCTAssertTrue(AppLocale.ar.isRTL, "Arabic must be right-to-left")
        XCTAssertTrue(AppLocale.ur.isRTL, "Urdu must be right-to-left")
    }

    /// Every other language is LTR. This is the regression guard: adding RTL infra must not flip any
    /// existing language. Iterating `allCases` also future-proofs the guard as languages are added.
    func testAllNonArabicUrduLanguagesAreLTR() {
        for locale in AppLocale.allCases where locale != .ar && locale != .ur {
            XCTAssertFalse(locale.isRTL, "\(locale.rawValue) must remain left-to-right")
        }
    }

    /// Exactly two languages are RTL today (ar, ur) — no more, no less.
    func testExactlyTwoRTLLanguages() {
        let rtl = AppLocale.allCases.filter(\.isRTL)
        XCTAssertEqual(Set(rtl), [.ar, .ur])
    }

    // MARK: - layoutDirection mapping

    /// The RTL languages map to `.rightToLeft`; every other language maps to `.leftToRight`.
    func testLayoutDirectionMapping() {
        XCTAssertEqual(AppLocale.ar.layoutDirection, .rightToLeft)
        XCTAssertEqual(AppLocale.ur.layoutDirection, .rightToLeft)
        XCTAssertEqual(AppLocale.en.layoutDirection, .leftToRight)
        XCTAssertEqual(AppLocale.esMX.layoutDirection, .leftToRight)
        XCTAssertEqual(AppLocale.ja.layoutDirection, .leftToRight)
    }

    // MARK: - Arabic RTL verification (story 009 AC1/AC4)

    /// Story 009 (Arabic content) RTL verification: now that ar ships complete content, re-confirm the
    /// story-008 layout-direction contract holds for Arabic specifically — `.ar` is in the RTL set and
    /// maps to SwiftUI's `.rightToLeft`, so selecting Arabic renders the whole UI right-to-left
    /// (AC1/AC4). This is a focused regression guard for the ar locale, not new infrastructure; the
    /// applied-modifier env propagation for `.ar` is proven by
    /// `RTLEnvironmentHostingTests.testSelectedRTLLanguagePropagatesRightToLeft`.
    func testArabicSelectsRightToLeftLayout() {
        XCTAssertTrue(AppLocale.ar.isRTL, "Arabic must be right-to-left")
        XCTAssertEqual(
            AppLocale.ar.layoutDirection,
            .rightToLeft,
            "selecting Arabic must drive the app layout direction to .rightToLeft"
        )
    }

    // MARK: - Launch-time force-RTL override

    /// A bare `-HANA_FORCE_RTL` launch argument forces `.rightToLeft` — the simplest thing a UI test
    /// passes via `launchArguments`, so RTL is exercisable before ar/ur content exists.
    func testForceRTLLaunchArgument() {
        XCTAssertEqual(
            LayoutDirectionOverride.forcedDirection(from: [:], arguments: ["-HANA_FORCE_RTL"]),
            .rightToLeft
        )
        XCTAssertEqual(
            LayoutDirectionOverride.forcedDirection(from: [:], arguments: ["HANA_FORCE_RTL"]),
            .rightToLeft
        )
    }

    /// A truthy `HANA_FORCE_RTL` environment value forces RTL; a falsy value forces LTR.
    func testForceRTLEnvironmentValues() {
        for truthy in ["1", "true", "TRUE", "yes", "rtl"] {
            XCTAssertEqual(
                LayoutDirectionOverride.forcedDirection(from: ["HANA_FORCE_RTL": truthy], arguments: []),
                .rightToLeft,
                "\(truthy) should force RTL"
            )
        }
        for falsy in ["0", "false", "no", "ltr"] {
            XCTAssertEqual(
                LayoutDirectionOverride.forcedDirection(from: ["HANA_FORCE_RTL": falsy], arguments: []),
                .leftToRight,
                "\(falsy) should force LTR"
            )
        }
    }

    /// With no override set, `forcedDirection` is nil so the SELECTED language drives the direction.
    func testNoOverrideMeansLanguageWins() {
        XCTAssertNil(LayoutDirectionOverride.forcedDirection(from: [:], arguments: []))
        XCTAssertNil(
            LayoutDirectionOverride.forcedDirection(from: ["HANA_FORCE_RTL": "   "], arguments: [])
        )
        XCTAssertNil(
            LayoutDirectionOverride.forcedDirection(from: ["HANA_FORCE_RTL": "garbage"], arguments: [])
        )
    }
}
