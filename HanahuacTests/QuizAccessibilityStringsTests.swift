import XCTest
@testable import Hanahuac

/// Verifies that every accessibility (`a11y.*`) string key added for the quiz flows (story 004)
/// resolves to a real, non-empty value for ALL `AppLocale` cases through the fallback chain.
///
/// The quiz VoiceOver labels/values/hints are looked up at runtime via `L10n.string(_:locale:)`. A
/// key that is absent from every bundle in a locale's chain would surface the raw key (Apple's
/// contract), which VoiceOver would then read aloud verbatim — a regression this test guards against.
/// Because en (and the es-MX base) ship every `a11y.*` key, the chain (selected → es-MX → en) always
/// resolves even for the downloadable locales whose pack is not embedded in a clean CI test host.
final class QuizAccessibilityStringsTests: XCTestCase {
    /// Every accessibility key introduced for the quiz flows.
    private let a11yKeys: [String] = [
        "a11y.prompt.label",
        "a11y.progress",
        "a11y.score",
        "a11y.graduated",
        "a11y.active",
        "a11y.answer_field.label",
        "a11y.answer_field.hint",
        "a11y.check.hint",
        "a11y.next.hint",
        "a11y.option.hint",
        "a11y.state.selected",
        "a11y.state.correct",
        "a11y.state.incorrect",
        "a11y.state.not_answered",
        "a11y.feedback.correct",
        "a11y.feedback.incorrect",
        "a11y.summary.accuracy",
        "a11y.summary.result_icon",
        "a11y.done.hint"
    ]

    /// Each key resolves to a non-key, non-empty value for every locale via the fallback chain.
    func testEveryA11yKeyResolvesForAllLocales() {
        for locale in AppLocale.allCases {
            for key in a11yKeys {
                let resolved = L10n.string(key, locale: locale)
                XCTAssertNotEqual(
                    resolved, key,
                    "Key \(key) surfaced the raw key for locale \(locale.rawValue) — VoiceOver "
                        + "would read the identifier aloud."
                )
                XCTAssertFalse(
                    resolved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Key \(key) resolved to an empty string for locale \(locale.rawValue)."
                )
            }
        }
    }

    /// Parameterized accessibility strings keep their format specifiers so the runtime
    /// `String(format:)` calls in the views substitute correctly in every locale.
    func testParameterizedKeysPreserveFormatSpecifiers() {
        let doubleIntKeys = ["a11y.progress", "a11y.graduated"]
        let singleIntKeys = ["a11y.score", "a11y.active", "a11y.summary.accuracy"]
        for locale in AppLocale.allCases {
            for key in doubleIntKeys {
                let format = L10n.string(key, locale: locale)
                XCTAssertEqual(
                    format.components(separatedBy: "%d").count - 1, 2,
                    "Key \(key) must keep two %d specifiers for locale \(locale.rawValue)."
                )
            }
            for key in singleIntKeys {
                let format = L10n.string(key, locale: locale)
                XCTAssertEqual(
                    format.components(separatedBy: "%d").count - 1, 1,
                    "Key \(key) must keep one %d specifier for locale \(locale.rawValue)."
                )
            }
        }
    }
}
