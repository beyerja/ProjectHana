## Goal

Make element targeting reliable and stable by adding **accessibility identifiers** to the key interactive views the UI driver (story 001) navigates: Home rows / mode entries, the Settings entry point, the quiz controls (answer buttons / text input / submit), and the tap-a-country **map**. With stable ids in place the driver can target identifiers instead of localized labels.

This change is **additive only** — `.accessibilityIdentifier(...)` modifiers exclusively. It does **not** alter visible behavior, layout, or any user-facing string/copy.

## Naming scheme

| Identifier | Surface / element |
| --- | --- |
| `home.mode.<modeRaw>` | Home per-mode row button (`mapQuiz` \| `multipleChoice` \| `typeCapital` \| `nameFeature`); per-mode, not per-category. |
| `home.settings` | Home toolbar gearshape `NavigationLink` → `SettingsView`. |
| `home.progress` | Home "View progress" `NavigationLink` → `StatsView`. |
| `quiz.answer.<n>` | Multiple-choice / learning answer option button, `<n>` = zero-based option index. |
| `quiz.input` | Text-quiz answer `TextField` (`.unanswered` branch). |
| `quiz.submit` | Text-quiz "Check" `Button` (`.unanswered` branch). |
| `map.tapCountry` | Tap-a-country `Map` container (not the disabled reference map in `NameFeatureQuizView`). |
| `settings.language` | Settings Language `NavigationLink`. |
| `settings.syncToggle` | Settings iCloud Sync `Toggle`. |

## Summary of changes

- Added `home.mode.<modeRaw>`, `home.settings`, `home.progress` on the Home view.
- Added `quiz.answer.<n>` to `MultipleChoiceQuizView` and `LearningQuizView`.
- Added `quiz.input` / `quiz.submit` to `CapitalQuizView` and `NameFeatureQuizView`.
- Added `map.tapCountry` to the map container in `MapQuizView` and `MapLearningQuizView`.
- Added `settings.language` / `settings.syncToggle` on the Settings view.
- No visible/layout/copy change; identifiers are additive metadata only.

**8 view files touched.**

## Test plan

- [ ] Existing unit tests pass (no behavior change expected).
- [ ] SwiftLint passes.
- [ ] Identifiers match the documented naming scheme so action scripts (stories 003/004) can reference them.
