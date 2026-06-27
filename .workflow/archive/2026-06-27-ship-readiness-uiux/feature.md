# Feature: Ship-readiness UI/UX pass (driver-investigated)

## Goal

Make the Hanahuac app ready to ship to users by fixing the UI/UX defects found by driving the
real app with the `just ui-walkthrough` XCUITest driver. Every fix is **verified live with the
driver** (before/after screenshots + accessibility-element dumps), so quality is demonstrated, not
asserted.

## Investigation method (already done in the main session — do NOT re-derive)

Drove the booted iPhone 17 / iOS 26.5 sim through Home → all four quiz modes (Map, Multiple
Choice, Type Capital, Name Feature) → Progress → Settings → Language picker, via
`just ui-walkthrough <script> <run>`. Findings below each cite the observed evidence. Raw run
output lived under `.workflow/ui-walkthrough/<run>/` (gitignored) for `explore-quizzes`,
`explore-rest`, `mc-crash`, `explore-settings`.

## Acceptance Criteria

- [ ] **AC1 — Localize the Multiple-Choice quiz.** With the app UI in Spanish, the MC prompt
      currently renders in English ("What is the capital of Ukraine?", "What is the capital of
      Netherlands?") while the Type-Capital quiz is correctly Spanish ("¿Cuál es la capital de
      Micronesia?"). Route the MC prompt template AND the country/feature names through the existing
      l10n / `GeoNameResolver` system so the MC quiz matches the selected app language in every
      mode (countries, rivers, mountains, seas). Country phrasing must read naturally per locale
      ("Países Bajos", not "Netherlands"). Add the needed keys to ALL locales so `just l10n-check`
      passes. Verify with the driver: MC prompt is Spanish when the app is Spanish.
- [ ] **AC2 — Fix the intermittent quiz-exit crash.** Observed once: tapping **Salir** to exit the
      Multiple-Choice quiz right after the question auto-advanced left a blank white screen and
      dropped to the iOS home screen (accessibility tree went empty `[]` = app terminated); a clean
      repro did not reproduce it. Diagnose the quiz-session teardown / state race (focus on
      dismiss-while-advancing in the MC flow), harden it so exiting ANY quiz reliably returns Home
      without the app terminating, and add an automated regression test (unit/UI) if feasible.
      Verify with the driver: a tap-answer → Salir loop run several times never yields an empty tree.
- [ ] **AC3 — Fix the Settings "Idioma" double chevron.** The row shows two disclosure chevrons
      (`>  >`) — a manual chevron stacked on the `NavigationLink`'s built-in one. Show exactly one.
      Verify with the driver / screenshot.
- [ ] **AC4 — Fix the map-learning header icon.** "Aprendizaje en mapa" shows a blurry/duplicated
      icon next to the back button. Clean it up to a single crisp element. Verify with the driver.
- [ ] **AC5 — Map presentation polish (keep satellite base).** Keep `.mapStyle(.imagery)` — it is
      the deliberate, correct answer to the place-name-label problem (a standard MapKit style writes
      country/city names everywhere, revealing answers; iOS MapKit gives no fine label suppression).
      Improve the *presentation* only: tidy the overlay prompt card and the "Apple Maps / Legal"
      attribution placement, ensure consistent styling across Map and Name-Feature quizzes.
      **HARD CONSTRAINT: no place-name labels may be introduced** anywhere on the quiz map. Verify
      with the driver that no answer-revealing labels appear.
- [ ] **AC6 — Resolve redundant quiz back-navigation.** Quiz screens show both a back chevron AND a
      "Salir" button. Settle on one clear way back (keep the one that fits the nav model; the driver
      and the committed demo target the "Salir" label, so if it's removed, update
      `.workflow/ui-walkthrough/scripts/full-walkthrough.json` + the demo evidence accordingly).
      Verify with the driver.
- [ ] **AC7 — Label the Progress category table.** The per-category table header uses bare icons
      (circle / flame / refresh / star) with no legend. Add accessible labels and/or a visible
      legend so the columns (new / learning / review / mastered) are understandable. Verify with the
      driver (screenshot + element dump showing labels).
- [ ] **AC8 — Robust Type-Capital input layout.** The Type-Capital screen caught the iOS
      multilingual-keyboard onboarding card overlapping the bottom; confirm the answer field +
      "Verificar" button remain visible and usable when the keyboard is up (scroll/inset as needed).
      The system onboarding card itself is not the app's bug, but the layout must be robust to it.
      Verify with the driver.
- [ ] **AC9 — Demonstrated before/after evidence.** Capture driver walkthrough artifacts proving
      each fix; reference them in the story/verify logs.

## Constraints

- **iOS Simulator only** (iPhone 17 / iOS 26.5, the default `just` destination); bundle id
  `com.hanahuac.app`. Use the `just ui-walkthrough` driver (now on main) to verify every change.
- **Localization completeness:** any new strings/keys must be added to every locale so the static
  gate `just l10n-check` and the runtime completeness tests pass; reuse `GeoNameResolver` /
  language packs for feature names rather than hardcoding.
- **No place-name labels on the quiz map** (the reason satellite was adopted) — this is a hard
  correctness constraint, not a style preference.
- This feature touches **app code** (Views, L10n, map rendering), NOT workflow tooling, so the
  normal orchestrator worktree isolation applies (do NOT force an in-place run).
- Follow CLAUDE.md conventions: Read/Grep/Glob over shell inspection; allowlistable Bash shapes
  (no `cd &&`, heredocs, `$(…)`, or poll loops); `just lint` + `just test` must pass; project is
  generated from project.yml via `just generate` — never hand-edit pbxproj.
- The merge gate is the App-posted `code-owner-review` status check (app id 4144849) via
  `scripts/gh-review-bot.sh` — the now-working mechanism; the same review gates apply per PR.

## Out of Scope

- A full vector / non-MapKit quiz-map redesign (drawing country shapes on a plain background).
  Noted as a possible future enhancement; the satellite base stays for this pass.
- New quiz modes, new categories, or new app features.
- iCloud-sync behavior changes (the "No disponible" state in the sim is expected without an account).
- Reworking the spaced-repetition scheduler or data model.
