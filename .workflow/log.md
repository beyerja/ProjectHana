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
