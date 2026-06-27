<!-- independent-review -->
## Independent review — Round 1: APPROVED

Fresh, cold-context 4-eye review of the diff (4 files, +42/-8). No blocking findings.

### Hard constraints — all satisfied
- **Satellite base retained.** `.mapStyle(.imagery(elevation: .flat))` is present in all three views (`MapQuizView.swift:80`, `MapLearningQuizView.swift:102`, `NameFeatureQuizView.swift:241`). The diff does not touch these lines.
- **No place-name labels introduced.** No labeled map style, no `.standard`, no `pointsOfInterest`/`showsLabels` anywhere in `Hanahuac/Views/Quiz/`.
- **No vector-map redesign.** Changes are purely presentational (corner radius, padding, `.continuous` style, `VStack` spacing).
- **Scope respected.** Overlay-card radius unification, Apple Maps/Legal attribution clearance, and cross-quiz consistency only.
- **No new user-visible strings.** Diff adds no `L10n[...]` keys; `just l10n-check` scope is unaffected.

### What the change does
- Unifies the prompt/answer card corner radius to the shared `Theme.Metrics.cardRadius` (= 18), already used by `HomeView` — a genuine cross-quiz consistency win, not a new magic number.
- Adds `.padding(.bottom, 40)` to the Map-quiz feedback banners and `VStack(spacing: 12)` on the Name-Feature quiz body to keep MapKit's auto-rendered "Apple Maps / Legal" attribution clear of the cards.
- Adds `.workflow/ui-walkthrough/scripts/004-map-polish.json`. Verified the referenced accessibility identifiers resolve to real ones: `home.mode.mapQuiz` / `home.mode.nameFeature` (`HomeView.swift:103` → `home.mode.\(quizModeRawValue)`, raw values `mapQuiz`/`nameFeature` from `QuizModeID`) and `BackButton` (`MapLearningQuizView.swift:62`). The script is not a silent no-op.

### Non-blocking nit (posted inline)
- The feedback banner keeps a literal `cornerRadius: 14` while the prompt cards were unified to `Theme.Metrics.cardRadius`. Minor; does not block.

### AC reachability
All changes are in production view bodies on the live render path (not test-only). No new seam needs wiring into a composition root. ACs 1–3 are reachable at runtime; AC4 (lint/test/l10n) is reported green by CI.

Verdict: **APPROVED**. The formal `code-owner-review` merge gate is set by the separate code-owner-review agent.
