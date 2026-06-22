## Code-owner review — APPROVED

Independent second-eye verification of the map-quiz accessibility changes against story 005's spec. I read the diff directly (not via the review skill) and reached my own verdict.

### Acceptance criteria — independently confirmed, all reachable at runtime
- **AC1 — annotations expose labels/values to VoiceOver.** `MapFeaturePinView.body` sets `accessibilityLabel(name)`, a state-driven `accessibilityValue` (neutral = empty; correct/incorrect spoken via the pre-existing `a11y.state.*` keys), and `.isButton`. Wired into the live annotation closures of both `MapQuizView` and `MapLearningQuizView` — no composition-root gap.
- **AC2 — state conveyed without colour alone.** Pin value + feedback-banner label announce correct/incorrect and the correct feature name; learning progress is spoken via `learningProgressValue`, not just the coloured pill.
- **AC3 — sensible VoiceOver order / progress reachable.** Prompt banner collapsed with `.accessibilityElement(children: .ignore)`, label `a11y.map.prompt.label: <feature>`, and a progress value.
- **AC4 — Dynamic Type.** `multilineTextAlignment(.center)`, `ViewThatFits` pill reflow, and `firstTextBaseline` + `fixedSize` on the graduated row prevent truncation at AX sizes.

### Scope — compliant
SwiftUI/MapKit only, no new deps/capabilities/usage strings; additive modifiers only, quiz logic unchanged. The `AnswerState` (unanswered/correct/incorrect) and `MapFeaturePinView.State` switches are exhaustive and match the enum shapes; the `?? correctID` fallback is sound. New `a11y.map.*` keys live in the existing Accessibility namespace across all five embedded locales (`nah` resolves via the fallback chain); `QuizAccessibilityStringsTests` extended with all four keys plus format-specifier assertions (`a11y.map.progress` = 2× `%d`, `a11y.map.streak` = 1× `%d`).

### CI
`Build & Test` ran on the head commit (`66d5887`) and passed. `gitleaks` (`secret-scan.yml`) triggers only on PRs targeting `main`; this PR's base is `feat/appstore-readiness`, so its absence is by design — not an event-miss. No re-trigger required.

The two inline notes from the first reviewer (`.isButton` redundant with the wrapping `Button`; undecorated decorative overlays) are genuinely non-blocking.

Verdict: **APPROVED**.

<!-- code-owner-review -->
