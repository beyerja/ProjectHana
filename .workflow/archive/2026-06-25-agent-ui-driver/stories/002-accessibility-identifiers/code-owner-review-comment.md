<!-- code-owner-review -->
## Code-owner review — APPROVED

Independent second-eye pass (diff read directly, not via `/code-review`), confirming the `independent-review` verdict with my own judgment.

### What I verified myself
- **Additive only.** Every changed line is a new `.accessibilityIdentifier(...)` modifier or a `ForEach(Array(...enumerated()), id: \.element.id)` conversion. No `Text`/`L10n`/label/hint/copy touched; existing `.accessibilityLabel`/`.accessibilityHint`/`.accessibilityValue` are intact. No visible behavior/layout/copy change.
- **`enumerated()` keeps identity.** Both converted loops (`LearningQuizView`, `MultipleChoiceQuizView`) retain `id: \.element.id`, so SwiftUI view identity, diffing, selection, and animation are unchanged. `quiz.answer.<index>` is the stable zero-based position the spec calls for.
- **Naming scheme matches the spec vocabulary exactly:** `home.mode.<modeRaw>`, `home.settings`, `home.progress`, `quiz.answer.<n>`, `quiz.input`, `quiz.submit`, `map.tapCountry`, `settings.language`, `settings.syncToggle`.
- **Correct exclusion:** `NameFeatureQuizView.featureMap` (disabled reference map) is NOT tagged `map.tapCountry` — that file only gains `quiz.input`/`quiz.submit`.
- **No debris:** only the 8 expected view files changed; no `verify-script.json`, `verify001.xctestplan`, or `.workflow/ui-walkthrough/`.

### Acceptance criteria
All six ACs reachable at runtime — Home rows + Settings/Progress entry points, quiz answer/input/submit controls, tap-a-country map, and Settings controls all carry stable identifiers; additive-only; consistent documented naming. The identifiers are real production view modifiers (not test-only seams), so stories 003/004 can target them directly.

### CI
Head commit `8106703`: **Build & Test = success**, "Detect build-relevant changes" gate ran (workflow fired correctly, no event-miss). No self-heal needed.

Formal `APPROVE` state submitted as `Hanahuac-Bot` via the wrapper.
