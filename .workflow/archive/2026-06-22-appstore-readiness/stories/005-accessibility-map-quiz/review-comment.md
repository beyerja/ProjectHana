<!-- independent-review -->
## Independent review — Round 1: APPROVED

Cold-context 4-eye review of the map-quiz accessibility changes against story 005's spec. No blocking findings.

### Acceptance criteria — all met and reachable at runtime
- **MapKit annotations expose labels/values** — `MapFeaturePinView` now sets `accessibilityLabel(name)`, an `accessibilityValue` driven by state (correct/incorrect, neutral = no value), and `.isButton`. Applied directly in the live view body; both `MapQuizView` and `MapLearningQuizView` wrap the pin in a `Button` and add `a11y.map.pin.hint` that clears once answered. No composition-root wiring gap.
- **Interactive state without color alone** — pin value + feedback-banner label announce correct/incorrect and the correct feature name; learning streak/graduated progress is spoken via `learningProgressValue`, not just the colored pill.
- **Sensible VoiceOver order / progress reachable** — prompt banner collapsed into one element (`children: .ignore`) with label `a11y.map.prompt.label: <feature>` and a progress value (`a11y.map.progress`).
- **Dynamic Type** — prompt/feedback text uses `multilineTextAlignment(.center)` and wraps; streak pills reflow via `ViewThatFits`; completion graduated row uses `firstTextBaseline` + `fixedSize` so the count is not truncated at AX5.

### Scope constraints — satisfied
- SwiftUI/SwiftData/MapKit only; no new dependencies, no capabilities/usage strings.
- Additive accessibility modifiers; quiz logic unchanged. New helpers are private, file-local; switches over `AnswerState` / pin `State` are exhaustive and match the enum shapes.
- New `a11y.map.*` keys added under the existing Accessibility section in all five embedded locales (en, es-MX, de, fr, ko); `nah` resolves via the fallback chain. `QuizAccessibilityStringsTests` extended with all four keys and their format-specifier assertions (`a11y.map.progress` = 2× `%d`, `a11y.map.streak` = 1× `%d`) across every `AppLocale`.

### Non-blocking notes (posted inline)
1. `.isButton` on `MapFeaturePinView` is redundant with the wrapping `Button`.
2. `featureOverlays(...)` regions have no explicit a11y treatment — acceptable as decorative shading; flagged as a conscious scope decision.

Verdict: **APPROVED**. The formal code-owner review is submitted separately.
