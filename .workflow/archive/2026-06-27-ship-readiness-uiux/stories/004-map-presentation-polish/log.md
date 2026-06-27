# Log — 004 Map presentation polish (keep satellite base)

2026-06-27 break-tasks: DONE, 9 tasks

2026-06-27 implement-story: DONE — all 9 tasks complete.

2026-06-27T00:21:14+02:00 merge-pr: DONE

## AC9 ui-walkthrough evidence (iPhone 17 / iOS 26.5, booted)
Script: `.workflow/ui-walkthrough/scripts/004-map-polish.json` (covers Map quiz `home.mode.mapQuiz`
+ Name-Feature quiz `home.mode.nameFeature`; dumpTree + screenshot for each).
- BEFORE: `/Users/Private/Documents/Code/ProjectHana-worktrees/ship-readiness-uiux/.workflow/ui-walkthrough/before/`
  - Map quiz: `before/004-step.png` (+ `.json`) — Name-Feature quiz: `before/010-step.png` (+ `.json`)
- AFTER: `/Users/Private/Documents/Code/ProjectHana-worktrees/ship-readiness-uiux/.workflow/ui-walkthrough/after/`
  - Map quiz: `after/004-step.png` (+ `.json`) — Name-Feature quiz: `after/010-step.png` (+ `.json`)

## Task 002 audit + shared target spec
Divergence found:
- MapQuizView / MapLearningQuizView floating prompt card: `.regularMaterial`, cornerRadius 16;
  feedbackBanner `padding(.bottom, 24)` — close to MapKit's bottom-edge "Apple Maps / Legal".
- NameFeatureQuizView answer card: `Theme.Palette.surface`, cornerRadius 20, NO top prompt card;
  card abutted the map (`VStack(spacing: 0)`), covering the bottom attribution row.
Shared target: unify card corner radius to `Theme.Metrics.cardRadius` (18, `.continuous`) across all
three; keep `.regularMaterial` for the floating map-quiz cards and `Theme.Palette.surface` for the
Name-Feature bottom panel; add bottom attribution clearance (feedback banner bottom inset 40 on map
quizzes; 12pt gap between map and answer card on Name-Feature).

## Verification
- `.mapStyle(.imagery(elevation: .flat))` retained in all three views (unchanged).
- AFTER screenshots + a11y dumps confirm NO place-name labels on either map; only quiz pin/prompt
  labels + the "Legal" attribution appear. Overlay card + attribution tidy and consistent.
- Task 006: no new user-visible strings introduced → skipped; `just l10n-check` PASS.
- Task 007: no files added/removed; `project.yml` unchanged → no `just generate` needed.
- `just lint`: PASS. `just test`: TEST SUCCEEDED. `just l10n-check`: PASS.
- `just install` skipped: changes only adjust corner radius / padding / spacing on existing SwiftUI
  view bodies using patterns already in the project; no new files or new UI modifiers/APIs.

2026-06-27 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/188

2026-06-27 independent-review: APPROVED — all hard constraints met (satellite base retained x3, no labels, no vector redesign, no new strings); only one non-blocking radius-consistency nit posted inline.

2026-06-27 code-owner-review: APPROVED — hard constraints re-verified (satellite base retained, no place-name labels, no vector redesign, scope-limited, no new strings); CI green; gate check success posted on 7638243 by app 4144849 (read-back confirmed).

2026-06-27 verify-story: DONE — verified against merged origin/main (squash 3820c9f, PR #188). AC1: .mapStyle(.imagery(elevation: .flat)) present in MapQuizView.swift:80, MapLearningQuizView.swift:102, NameFeatureQuizView.swift:241. AC2: AFTER screenshots (after/004-step.png Map quiz, after/009-step.png Name-Feature) show satellite base with NO place-name labels. AC3: diff unifies card radius to Theme.Metrics.cardRadius (.continuous) across all 3 views, feedback banner bottom inset 40, NameFeature 12pt gap — attribution tidy/visible in AFTER shots. AC4: l10n-check PASS, lint PASS, test ** TEST SUCCEEDED **. AC9: before/ + after/ screenshots + accessibility JSON dumps exist and inspected; BEFORE vs AFTER distinct and genuine.
