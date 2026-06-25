# 002 — Accessibility identifiers on key interactive views

## Title
Add accessibility identifiers to the key views the driver needs to target

## Goal
Make element targeting reliable and stable by adding **accessibility identifiers** to the key
interactive views the driver navigates: Home rows/mode entries, the Settings entry point, the
quiz controls (answer buttons / input), and the tap-a-country **map**. The change is minimal and
additive — it must NOT alter visible behavior, layout, or user-facing copy. With identifiers in
place the driver (story 001) can target stable ids instead of localized labels.

## Acceptance Criteria
- [ ] Home screen: each mode/row entry and the Settings entry point carry a stable
      `accessibilityIdentifier` (e.g. `home.mode.<x>`, `home.settings`).
- [ ] Quiz screens: the primary interactive controls (answer options / text input / submit)
      carry stable identifiers.
- [ ] The tap-a-country map view carries a stable identifier so the driver can resolve it for a
      normalized `mapTap`.
- [ ] Settings screen: the controls the walkthrough touches carry stable identifiers.
- [ ] No change to visible behavior, layout, or any user-facing string/copy; identifiers are
      additive metadata only (verified by existing unit tests + lint still passing).
- [ ] Identifiers follow a consistent, documented naming scheme so the action scripts in
      story 003/004 can reference them.

## Notes / Constraints
- Additive only — `.accessibilityIdentifier(...)` modifiers; do not touch labels shown to users.
- Independent of story 001 at the build level (story 001's driver works by label without these),
  but this story makes the demonstrated walkthrough in story 004 robust.

## Accessibility identifiers — naming-scheme reference

The stable accessibility-identifier vocabulary the driver (story 001) and the action scripts
(stories 003/004) target. All identifiers are additive `.accessibilityIdentifier(...)` metadata —
they never change visible behavior, layout, labels, or any user-facing string.

| Identifier | Surface / element |
| --- | --- |
| `home.mode.<modeRaw>` | Home per-mode row button. `<modeRaw>` = `HomeQuizMode.quizModeRawValue`, one of `mapQuiz` \| `multipleChoice` \| `typeCapital` \| `nameFeature`. The id is per-mode (not per-category): the same mode under multiple categories shares one id, since the driver navigates by mode. |
| `home.settings` | Home toolbar gearshape `NavigationLink` pushing `SettingsView`. |
| `home.progress` | Home "View progress" `NavigationLink` pushing `StatsView`. |
| `quiz.answer.<n>` | Multiple-choice / learning answer option button, `<n>` = zero-based option index (stable position). Applied in `MultipleChoiceQuizView` and `LearningQuizView`. |
| `quiz.input` | Text-quiz answer `TextField` (`.unanswered` branch). Applied in `CapitalQuizView` and `NameFeatureQuizView`. |
| `quiz.submit` | Text-quiz "Check" `Button` (`.unanswered` branch). Applied in `CapitalQuizView` and `NameFeatureQuizView`. |
| `map.tapCountry` | Tap-a-country `Map` container in `MapQuizView` and `MapLearningQuizView` `quizBody(session:)`. The id is on the map container (per the driver's `mapTap` contract); pins are SwiftUI buttons inside the map. NOT applied to the disabled reference map in `NameFeatureQuizView.featureMap`. |
| `settings.language` | Settings Language `NavigationLink`. |
| `settings.syncToggle` | Settings iCloud Sync `Toggle`. |
