# Feature: country-quiz-modes-fix

## Goal

Make the two text-based quiz modes first-class and fix the misnamed "Name the Country" mode so it
matches what the user actually wants:

1. **Full parity for the text-based modes.** "Type the Capital" and the new "Name that feature" mode
   must work like the map and multiple-choice modes: they participate in BOTH the *new* pile and the
   *pending* pile, seed/advance cards through the existing SM-2 scheduler, and record progress
   snapshots. (Today `typeCapital` and `nameCountry` have `supportsNew = false` and only run on due
   cards.)

2. **Replace the capital-based "Name the Country" mode with a map-pin "Name that feature" quiz that
   spans all four categories.** Today `nameCountry` shows a capital and asks for the country
   (`CapitalQuizView(mode: .countryOfCapital)`), and the mode only appears under the *Countries*
   category. The user misunderstood the old quiz; what they want is a single mechanic shared by
   **countries, rivers, mountains, and seas**: the map is shown with the target feature's pin marked,
   and the user TYPES the feature's name. Show feature → type its name.

"Type the Capital" keeps its existing capital-based mechanic (unchanged), but gains new+pending parity
per goal 1. It remains a Countries-only mode.

## Acceptance Criteria

- [ ] A new map-pin "Name that feature" quiz mode is offered for all four categories (countries,
      rivers, mountains, seas). It shows a map centered on the current feature's pin (reusing the same
      pin/region machinery as the map-tap quiz) and a text field; the user types the feature's name.
- [ ] Answer matching reuses the existing localized-name + English-fallback, case-insensitive,
      whitespace-trimmed comparison (as in `TextQuizSession.checkAnswer`). The accepted answers are the
      feature's `localizedName(for: currentLocale)` (primary) and its English `name` (fallback when the
      locale isn't English). Korean and Nahuatl resolve their localized name via the existing
      ko → es → en / nah → es → en fallback chain and that localized name is accepted.
- [ ] Correct/incorrect feedback reveals the correct feature name; a wrong answer schedules the card at
      SM-2 quality 1, a correct answer at quality 4 (matching the existing text quiz), and the session
      records a progress snapshot on each advance.
- [ ] The "Name that feature" mode and the "Type the Capital" mode both participate in the *new* pile
      and the *pending* pile: `HomeQuizMode.supportsNew` is `true` for both; the home tiles show New and
      Pending counts; the pile picker / direct-navigation routing works for each.
- [ ] When entered for the *new* pile, the mode seeds new cards (consistent with how map/multiple-choice
      learning modes promote new cards) and advances them through SM-2 + progress recording.
- [ ] "Type the Capital" retains its current capital-of-country mechanic and stays a Countries-only
      mode; it is enabled (reachable) with full new+pending parity.
- [ ] The home screen no longer offers the old capital-based "Name the Country" mode; the replaced mode
      is the map-pin "Name that feature" mode described above, wired under every category.
- [ ] UI strings (mode titles, prompt, placeholder, feedback, nav titles, nothing-due) are localized
      across all shipped locales (en, fr, de, es-MX, ko, nah) consistent with the existing L10n setup.
- [ ] Existing quiz/progress/L10n tests still pass, and new unit tests cover: the name-matching factory
      (localized + English-fallback, including ko/nah), new+pending parity for both text modes, and SM-2
      scheduling + progress recording on advance.

## Constraints

- Reuse existing infrastructure rather than duplicating it: `MappableFeature` (gives
  `localizedName(for:)` + `pinCoordinate` + overlays for all categories), `MapFeatureCatalog.features(for:)`,
  the map region/annotation helpers, `SM2Scheduler`, `StreakTracker`, `ProgressStatsStore.recordSnapshot`,
  and the existing card-pile model (`cardStore.newCards(for:)` / `dueCards(for:)`). Prefer extending the
  generic, category-driven types over adding category-specific branches.
- Keep the `TextQuizSession` answer-matching semantics (trimmed, case-insensitive, primary localized +
  optional English fallback). Generalize its question factories to cover any `MappableFeature`, not just
  `Country` capitals.
- Swift / SwiftUI / SwiftData app built via the project `justfile` recipes and direnv/Nix toolchain; do
  not hardcode Nix paths.
- No new CI checks are introduced by this feature, so there is no blocking-vs-async CI split to capture.

## Out of Scope

- Changing the map-tap quiz, multiple-choice quiz, or map-learning flows beyond what is needed to share
  their pin/region/session machinery.
- New geography data/content; this feature reuses the already-bundled features and their localized names.
- Changing the SM-2 algorithm, streak logic, or the progress/stats schema.
- Adding a "type the capital" variant for rivers/mountains/seas (those categories have no capital). Only
  the map-pin "Name that feature" mode is added across all categories.
