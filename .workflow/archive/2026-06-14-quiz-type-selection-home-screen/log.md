# Workflow Log

## 2026-06-13 — map-quiz-bug-fixes

### Phase: Clarify
- Investigated the two reported bugs in the codebase before spawning agents.
- **Bug 1 (overlay)**: `MapPolygon.foregroundStyle` is called with `session.answerState.polygonFillColor(for: id)` but SwiftUI's `Map` content builder may not track `@Observable` changes reactively, causing polygons to render with `.clear` permanently. The `country-borders.json` file is present and valid (175 entries). Fix: ensure the color is computed in a way SwiftUI can track — likely by reading `answerState` outside the `Map` builder or using a workaround.
- **Bug 2 (persistence)**: `MapLearningSession` does not use `ActiveSetStore`. Fix: add category + store parameters mirroring `LearningSession`.
- Feature spec written to `.workflow/feature.md`.
- Status: DONE

### Phase: Break Stories
- Stories written to `.workflow/stories.md`
- Story 001: Fix country polygon overlay (Map content builder doesn't track @Observable)
- Story 002: Persist New pile card selection (MapLearningSession missing ActiveSetStore)
- Status: DONE

### Phase: Assess Project Health
- Project builds via `just build-mac`; tests via `just test` (iOS Simulator)
- No setup stories needed; project is healthy
- Existing tests cover MapLearningSession mechanics but not persistence (gap for Story 002)
- Status: DONE

### Phase: Story Loop — Story 001 (fix polygon overlay)
- Root cause confirmed: `@MapContentBuilder` closure doesn't track `@Observable`; `session.answerState` was read inside `Map { }` without registering a dependency.
- Fix: captured `let answerState = session.answerState` outside `Map {}` in `quizBody`; updated `pinState` signature.
- Applied to both `MapQuizView` and `MapLearningQuizView`.
- Build: SUCCEEDED
- Status: DONE

### Phase: Story Loop — Story 002 (New pile persistence)
- Added `category` + `store` params to `MapLearningSession.init`; added rehydration + graduation persistence mirroring `LearningSession`.
- Updated `MapLearningQuizView` to accept `category` and create `UserDefaultsActiveSetStore`.
- Updated `LearningModePickerView` to pass `category: .country`.
- Added 5 new tests in `MapLearningTests.swift`.
- Build: SUCCEEDED; Tests: PASSED
- Status: DONE

### Phase: Verify Feature
- Both bugs fixed; build succeeds; full test suite passes.
- Status: DONE

### Phase: Evaluate Workflow
- Both bugs were fully diagnosable from code reading alone — no ambiguity requiring user clarification beyond what was given.
- The `@MapContentBuilder` observation gap is a subtle but important SwiftUI pitfall; a comment was added in code to document why the pattern is necessary.
- The `MapLearningSession` persistence gap was a clear omission relative to `LearningSession`; the fix mirrors the existing pattern exactly.
- Tests were extended to cover the new persistence behaviour; all 5 new tests pass on first attempt.
- No regressions — full test suite passes.
- Workflow ran efficiently: code was read first to fully understand both bugs before touching any files.
- Improvement for future workflows: when a feature is marked "previously implemented but not working", always check `@Observable` + non-`@ViewBuilder` closures (Map, Chart, etc.) as a potential observation gap.
- Status: DONE

### Phase: Archive
- Stories and feature complete; commit pushed to branch chore/close-map-quiz-learning-workflow.
- Status: DONE

2026-06-13T18:32:01Z merge-pr: DONE

## 2026-06-13 — automated-dependency-updates

### Phase: Assess Project Health
- Build succeeds (just build-mac: BUILD SUCCEEDED)
- Feature is pure infrastructure (YAML files only) — no Swift code changes, no setup stories needed
- No blockers; project is healthy
- Status: DONE

### Phase: Break Stories
- Story 001: Add Dependabot configuration (.github/dependabot.yml) for github-actions + swift ecosystems
- Story 002: Add Nix flake.lock update workflow (.github/workflows/update-flake-lock.yml) — weekly cron, opens PR via peter-evans/create-pull-request, no auto-merge
- Status: DONE

### Phase: Clarify
- Explored codebase: only Nix flake (flake.nix, no flake.lock yet) and SPM (Package.resolved, no current pins) plus GitHub Actions (ci.yml with actions/checkout@v6). No CocoaPods/npm/Cargo.
- Decision: Dependabot for github-actions + swift ecosystems; dedicated GitHub Actions workflow for Nix flake.lock updates (Dependabot does not support Nix).
- Supply-chain delay satisfied by: weekly schedule + no auto-merge (human review required before merge).
- Prerequisite: flake.lock bootstrapped on first workflow run (nix flake update creates it if absent).
- Feature spec written to .workflow/feature.md.
- Status: DONE

### Phase: Story Loop — Story 001 (Dependabot config)
- Created .github/dependabot.yml with github-actions + swift ecosystems, weekly Monday 09:00 UTC schedule, open-pull-requests-limit 5, no auto-merge
- Status: DONE

### Phase: Story Loop — Story 002 (Nix flake.lock update workflow)
- Created .github/workflows/update-flake-lock.yml
- Weekly cron Sundays 02:00 UTC + workflow_dispatch
- DeterminateSystems/nix-installer-action@v22 installs Nix; nix flake update regenerates lock
- peter-evans/create-pull-request@v8 opens PR on automated/update-flake-lock branch
- No auto-merge; PR body explains supply-chain rationale
- Status: DONE

### Phase: Create PR
- PR #53 opened: feat(deps): add automated dependency updates (Dependabot + Nix flake)
- Branch: feat/automated-dependency-updates → main
- Status: DONE

### Phase: Wait for CI
- CI run 27475733361: Build & Test job SUCCEEDED (56s, macos-15-arm64)
- Status: DONE

### Phase: Open Dependency PRs Check
- Checked for open PRs from Dependabot / flake-lock workflow — none open yet (expected: workflow just configured, hasn't run yet)
- No existing dependency PRs to review or merge
- Status: DONE

### Phase: Verify Feature
- .github/dependabot.yml: valid, two ecosystems (github-actions + swift), weekly schedule, no auto-merge
- .github/workflows/update-flake-lock.yml: valid, cron "0 2 * * 0" (Sundays 02:00 UTC), workflow_dispatch present, ubuntu-latest runner, Nix installer + nix flake update + create-pull-request, no auto-merge
- workflow_dispatch not yet triggerable (workflow file not yet on default branch at time of verify) — expected; becomes live post-merge
- CI: PASS
- Status: DONE

### Phase: Merge PR
- PR #53 squash-merged to main at 2026-06-13T18:53:56Z (commit 9ed5414)
- Status: DONE

### Phase: Evaluate Workflow
- Feature was purely infrastructure (YAML only) — no Swift code to build/test locally. The workflow handled this correctly by skipping setup stories and going straight to implementation.
- Verify step correctly identified that workflow_dispatch cannot be tested until the workflow file lands on main; the static config review + CI pass was sufficient evidence.
- The "check for open dependency PRs" additional step added by the user was appropriate: Dependabot had not yet run (newly configured), so there was nothing to merge. Future runs of this workflow after a period of operation should re-check for queued dependency PRs.
- Story ordering (Assess → Break → Clarify) was slightly inverted in log vs execution — the Clarify phase actually drove the story decomposition. For pure-infrastructure features, Clarify should come before Break Stories to avoid reworking the story list.
- Action version pinning: used latest known versions (DeterminateSystems/nix-installer-action@v22, peter-evans/create-pull-request@v8) rather than guessing from training data — correct per feedback-github-actions-versions.md.
- Improvement for future workflows: for CI-only / infra features with no local runtime surface, the verify step should immediately classify as "GitHub Actions surface" and dispatch the workflow if possible, rather than defaulting to static review only.
- Status: DONE

### Phase: Archive
- Closing artifacts committed and pushed to main
- Status: DONE

## 2026-06-14 — quiz-type-selection-home-screen

### Phase: Clarify
- Explored full navigation stack: HomeView → CategoryDetailView → LearningModePickerView / QuizModePickerView (3 taps for Countries; 2 for other categories)
- User clarified: show all quiz modes on home screen, pile picker only when both new AND pending have cards, 1 tap otherwise; all categories; counts visible on buttons
- Feature spec written to .workflow/feature.md
- Status: DONE

### Phase: Break Stories
- Story 001: Rewrite HomeView with per-category quiz-mode buttons and pile counts
- Story 002: PilePickerView and end-to-end navigation
- Story 003: Remove obsolete screens (CategoryDetailView, LearningModePickerView, QuizModePickerView)
- Implemented all three stories in a single commit (tightly coupled)
- Status: DONE

### Phase: Implementation
- Added `Hashable` to `CardCategory`
- Added `QuizRoute.swift`: `HomeQuizMode`, `Pile`, `QuizRoute` enums for type-safe NavigationStack path navigation
- Rewrote `HomeView.swift`: per-category sections with quiz-mode buttons; new/pending pill counts; `NavigationStack(path:)` with `navigationDestination(for: QuizRoute.self)`
- Added `PilePickerView.swift`: shows New / Pending pile buttons using `NavigationLink(value:)` routing into the same navigation stack
- Deleted `CategoryDetailView.swift`, `LearningModePickerView.swift`, `QuizModePickerView.swift`
- Updated `project.pbxproj`: removed 3 old files, added 2 new files
- Status: DONE

### Phase: Create PR
- PR #55 opened: feat(home): quiz type selection on start screen (1–2 taps)
- Branch: feat/quiz-type-selection-home-screen → main
- Status: DONE

### Phase: Wait for CI
- CI run 27480860176: Build & Test SUCCEEDED (56s, macos-15)
- Status: DONE

### Phase: Merge PR
- PR #55 squash-merged to main at 2026-06-14 (commit 6f8e442)
- Status: DONE

### Phase: Evaluate Workflow
- Subagent workflow hit a permissions wall (Write/Edit denied) and could not complete the clarify-feature step; had to fall back to direct implementation in the main conversation. This was slower but worked correctly. Root cause: subagent lacked the auto-approved permissions the parent conversation had.
- Navigation architecture decision: used `NavigationStack(path:)` + `navigationDestination(for: QuizRoute.self)` + programmatic path appending rather than closure-based `NavigationLink`. This avoids nested `@ViewBuilder` conditional type issues and keeps PilePickerView navigating via `NavigationLink(value:)` into the same stack cleanly.
- All 3 stories were implemented in one commit because they were logically inseparable — deleting the old views only makes sense once the new flow is fully wired up.
- No new L10n keys were needed; all existing keys (`home.tile.new`, `home.tile.pending`, `quiz.mode.*.title`) were reused.
- The `project.pbxproj` required manual editing to register new files and remove deleted ones — this is a recurring friction point.
- Improvement for future workflows: when subagent permissions fail, fall back to main conversation immediately rather than retrying.
- Improvement: when multiple stories are inseparable (delete-only story depends entirely on add-new-code story), merge them into one story upfront.
- Status: DONE

### Phase: Archive
- Status: DONE
