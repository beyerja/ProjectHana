## Tasks

Context for all tasks — REUSE the existing `a11y.*` namespace from story 004; do NOT create a new
namespace or helper. Relevant existing files:
- Localization (6 locales, all `a11y.*` keys live under the
  `/* Accessibility (VoiceOver) — quiz flows */` section):
  - `Hanahuac/en.lproj/Localizable.strings` (en — final fallback; ships all 19 keys)
  - `Hanahuac/es-MX.lproj/Localizable.strings` (es-MX — base of the nah→es-MX→en chain; ships all 19)
  - `Hanahuac/de.lproj/Localizable.strings`, `Hanahuac/ko.lproj/Localizable.strings`,
    `Hanahuac/fr.lproj/Localizable.strings` (ship all 19)
  - `Hanahuac/nah.lproj/Localizable.strings` (downloadable pack — ships only the embedded subset;
    resolves the rest via the fallback chain, so new keys need NOT be added here)
- Resolution test to EXTEND (do not create a new test file):
  `HanahuacTests/QuizAccessibilityStringsTests.swift`
- Lookup APIs already in use: `L10n["key"]` and `L10n.string(_:locale:)` (no new helper needed).
- Target views: `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`,
  `Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`,
  `Hanahuac/Views/Quiz/MapQuiz/MapFeatureRendering.swift` (shared `MapFeaturePinView`).
- All work is additive view modifiers + new string keys; SwiftUI/MapKit only, no new dependencies,
  no signing/capabilities/usage-description changes.

- [x] 001: Add the new map-quiz `a11y.*` string keys to `Hanahuac/en.lproj/Localizable.strings` and
      `Hanahuac/es-MX.lproj/Localizable.strings` (and mirror into `de`, `ko`, `fr`; skip `nah` per the
      downloadable-pack pattern). Place them in the existing
      `/* Accessibility (VoiceOver) — quiz flows */` section. New keys cover the map-pin annotation
      label/value/hint, the tap-on-map prompt, the map-quiz progress, and the reveal/incorrect target
      name — e.g. `a11y.map.pin.hint` ("Double-tap to choose this place."),
      `a11y.map.prompt.label` ("Find on the map"), `a11y.map.progress` ("Place %d of %d"),
      `a11y.map.streak` ("%d of 3 correct in a row"). Reuse existing keys where they already fit
      (`a11y.state.correct`, `a11y.state.incorrect`, `a11y.feedback.correct`,
      `a11y.feedback.incorrect`, `a11y.done.hint`, `a11y.graduated`) — do NOT duplicate them.

- [x] 002: Make the map-quiz annotation pin accessible in `MapFeaturePinView`
      (`Hanahuac/Views/Quiz/MapQuiz/MapFeatureRendering.swift`). The pin is currently a plain
      Circle+Text inside a Button with an empty `Annotation("")` title, so VoiceOver sees nothing
      meaningful. Add `.accessibilityElement(children: .ignore)`, an `.accessibilityLabel` (the
      feature `name`), an `.accessibilityValue` driven by `state` (neutral → "" or
      `a11y.state.not_answered`; `.correct`/`.correctRevealed` → `a11y.state.correct`;
      `.incorrectTapped` → `a11y.state.incorrect`) so correct/incorrect state is conveyed without
      relying on color alone, and `.accessibilityAddTraits(.isButton)`. Keep it a pure presentational
      change to the shared pin so both map views inherit it.

- [x] 003: Wire the annotation Buttons in `MapQuizView.quizBody`
      (`Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`) for VoiceOver: add `.accessibilityHint`
      (`a11y.map.pin.hint`) that disappears once answered, and confirm the disabled state
      (`answerState != .unanswered`) is reflected to VoiceOver. Ensure the pin's accessibility label
      reads the localized feature name (`feature.localizedName(for:)`), matching task 002.

- [x] 004: Wire the annotation Buttons in `MapLearningQuizView.quizBody`
      (`Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`) with the same `.accessibilityHint`
      (`a11y.map.pin.hint`) and disabled-state handling as task 003. Same structure as MapQuizView's
      annotation closure.

- [x] 005: Make the `promptBanner` in `MapQuizView`
      (`Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`) a single sensible VoiceOver element: collapse
      the three stacked Texts (tap-on-map caption, current feature name, "n / total") with
      `.accessibilityElement(children: .combine)` or `.ignore` + an `.accessibilityLabel`
      (`a11y.map.prompt.label` + feature name) and `.accessibilityValue`
      (`String(format: L10n["a11y.map.progress"], reviewedCount + 1, cards.count)`), so order and
      content are spoken clearly rather than as raw fragments.

- [x] 006: Make the `promptBanner` in `MapLearningQuizView`
      (`Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`) a single VoiceOver element: combine
      the feature name, graduated count (`a11y.graduated`), and per-card streak
      (`a11y.map.streak` for `consecutiveCorrect`) into a clear label/value pair so the learning
      progress is conveyed without relying on the colored streak pill alone.

- [x] 007: Add VoiceOver labels to the `feedbackBanner` in both
      `MapQuizView` and `MapLearningQuizView` (the colored correct/incorrect banner): announce
      success via `a11y.feedback.correct` / failure via `a11y.feedback.incorrect` plus the revealed
      correct feature name, so the result is not conveyed by banner color alone. (Re-uses the existing
      feedback keys; no new keys needed beyond task 001.)

- [x] 008: Verify Dynamic Type for the map-quiz non-map chrome and fix concrete clipping/truncation at
      the largest accessibility sizes. Audit `MapQuizView` and `MapLearningQuizView`:
      `promptBanner` (fixed `.padding` rounded-rect banner with stacked/HStack Texts — the
      MapLearningQuizView HStack of graduated-count + streak is the highest truncation risk),
      `feedbackBanner`, the exit toolbar button, and `MapLearningQuizView.completionView`. Apply
      minimal fixes (allow wrapping / `.lineLimit`+`.minimumScaleFactor` / `.fixedSize` / let the
      HStack reflow) so text is not clipped at `AX5` / `.accessibilityExtraExtraExtraLarge`. The map
      surface itself is exempt (MapKit tiles do not scale with Dynamic Type).

- [x] 009: Extend `HanahuacTests/QuizAccessibilityStringsTests.swift` (do NOT add a new test file) to
      cover the new map-quiz keys from task 001: add them to the `a11yKeys` array (asserts each
      resolves to a non-raw, non-empty value for every `AppLocale` via the fallback chain) and add any
      parameterized keys to the format-specifier lists — `a11y.map.progress` to the two-`%d` group and
      `a11y.map.streak` to the one-`%d` group in `testParameterizedKeysPreserveFormatSpecifiers`.
