# Workflow Log — map-quiz-zoom-fix

Feature: Fix broken zoom/centering for river, mountain, and sea map quizzes.

## Step 0 — Worktree setup
- Slug: `map-quiz-zoom-fix`
- HANA_FEATURE_SLUG=map-quiz-zoom-fix
- Decision: WORKTREE created at `../ProjectHana-worktrees/map-quiz-zoom-fix` on branch `feat/map-quiz-zoom-fix` from `origin/main`. This is a feature/app bug fix, not workflow-tooling, so isolation applies.
- `direnv allow` run in worktree.

## Pre-clarify investigation (orchestrator)
- Map quiz region/zoom logic lives in `Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` (`QuizRegionMath`, `makeQuizAnnotations`).
- Region math is generic over `MappableFeature` and well unit-tested for countries (`MapQuizRegionHelperTests`).
- Country quiz is NOT reported broken; river/mountain/sea are. Pin coordinates come from `MappableFeature.pinCoordinate`:
  - Country: pole of inaccessibility.
  - Sea/Mountain: raw `lat`/`lon` from JSON.
  - River: midpoint vertex of path, else source/mouth midpoint.
- Camera applied via `position = .region(session.mapRegion)` in `MapQuizView` (and `MapLearningQuizView`).
- Suspected root cause to confirm: bad pin coordinates (swapped/sign) for the 3 categories, or region math edge case for their spreads. To be validated after clarification.

## Step 1 — Clarify (SKIPPED — already complete)
- The user supplied an authoritative clarified spec (scope, categories, wrong-center symptom, frequency, and a corrected acceptance bar: all candidate pins visible, correct pin NOT centered/distinguished). No ambiguity remained, so clarify-feature was not re-spawned.
- Deepened code investigation before writing the spec:
  - `QuizRegionMath.region(fittingPins:)` math is CORRECT and well-tested: centers on candidate-pin bounding box independent of the answer; fits all pins; clamps jitter. Not the bug.
  - Pin coordinates per category (`MappableFeature.pinCoordinate`) and bundled JSON (`seas.json` sane: Pacific lat 0 / lon -150) show NO lat/lon swap or sign error.
  - Leading hypothesis: overlay geometry (`featureOverlays`) — large sea/mountain `borderRings` and full-course river `linePath` polylines extend far beyond the pin bounding box; SwiftUI `Map` camera may frame the overlay extent instead of the intended `.region(mapRegion)`, pushing pins off-screen. Country borders are small/local, so country works. MECHANISM TO BE CONFIRMED IN CODE during implementation.
- Wrote `.workflow/feature.md` with the authoritative spec + acceptance criteria (incl. root-cause-confirmation and a regression test requirement).
- Next: break-stories.

## Step 2 — Break stories
- 2026-06-21 break-stories: DONE, 1 story. Single-root-cause bug fix — not over-decomposed. One vertically-sliced story (`001-fix-map-quiz-centering`) carrying root-cause-confirmation, all feature.md acceptance criteria (all candidate pins visible in both views for river/mountain/sea + country; correct pin not centered/distinguished; framing from full candidate bounding box; shared logic; regression test; just lint + just test pass).

## assess-project-health
- 2026-06-21 14:06:34 assess-project-health: DONE — none (mature repo: `just lint`/`just test`, CI ci.yml/lint.yml/codeql.yml/secret-scan.yml/odr-validation.yml, swiftformat/SwiftLint/Ruff/shellcheck/yamllint/nixfmt, populated .workflow/archive/; no genuine blocking gap)

## Step 4–7 — Story loop + per-story PR/CI/review/merge/verify
- 2026-06-21 story-workflow `001-fix-map-quiz-centering`: STATUS DONE. PR #143 merged to main via squash (SHA 2c5c4ef); feat branch deleted on remote. CI green; independent review APPROVED round 1 (fresh cold-context reviewer, separate spawn from implementer — 4-eye preserved; bot approval satisfied the main code-owner ruleset gate); verify-story DONE (7/7 criteria).
- Confirmed root cause: both views built `Map(position:)` with NO camera `bounds`; SwiftUI reconciles the seeded pin region against the natural extent of `featureOverlays` (full river `linePath` polylines, large sea/mountain `borderRings` polygons), re-framing the camera and pushing pins off-screen. Country works because its borders are small/local. Math / lat-lon-swap / data theories each ruled out in code.
- Fix: new `QuizRegionMath.cameraBounds(for:)` / `cameraDistance(for:)`, wired as `bounds:` identically into both views (one shared path, no per-category branch). Answer-independent framing preserved (no hint leak). +3 regression tests in MapQuizRegionHelperTests.
- NOTE: the single story already merged to `main`, so orchestrator step 5 (feature-level PR) is subsumed by PR #143. Proceeding to feature-level verification (step 7).
- 2026-06-21 verify-feature: DONE — all 7 feature-level acceptance criteria confirmed in merged code; just lint + just test green; just install rebuilt local app.

## Step 8 — evaluate-workflow
2026-06-21 evaluate-workflow: DONE
Telemetry outliers: none — no live `.workflow/telemetry/` this run (resumed worktree); analyzed qualitatively from story/feature logs. History (854 runs / 9 dates) reviewed for context.
Permission remediation: none this run — no `.workflow/telemetry/permissions-*.jsonl` present (graceful no-op).
Phase 2a flags: none — agent files reviewed are all project-specific guardrails, no genuine bloat.
Phase 2b: skipped applied-edit/before-after detail — no live telemetry boundary this run; qualitative only.
Improvements:
- feature_orchestrator.md Step 0: detect an existing worktree/branch and RESUME (read prior `.workflow/log.md`, skip completed phases) instead of `git worktree add -b` failing on a pre-existing path. Evidence: this run resumed an interrupted attempt (worktree+log existed, feature.md not yet written).
- implement-story.md: for bug-fix stories, confirm the root cause in code (and rule out competing theories) before editing. Evidence: the fix succeeded only because the spec demanded it; no agent file carried that generalizable instruction. The MapKit camera-bounds mechanism + 3 ruled-out theories validated the value of the up-front confirmation pass.
