# Workflow log — map-quiz-next-question-zoom

## 2026-06-17 — Step 0: Worktree setup
- Reused pre-existing clean worktree `../ProjectHana-worktrees/map-quiz-next-question-zoom` on branch `feat/map-quiz-next-question-zoom` (no commits ahead of main, no WIP, no prior .workflow state besides README+archive).
- Ran `direnv allow` in the worktree.
- HANA_FEATURE_SLUG=map-quiz-next-question-zoom
- Decision: worktree run (not in-place) — this changes app source, not workflow tooling.

## 2026-06-17 — Clarify
- Clarification provided by user as final; wrote .workflow/feature.md directly (clarify-feature step satisfied by user-supplied final spec).

## 2026-06-17 — break-stories: DONE, 1 story
- 001-clamp-quiz-region (single shared-helper fix covering both call sites; multi-story split would be artificial for a one-function bug fix).

## 2026-06-17 — assess-project-health: DONE — none
- Full tooling present: just test (XCTest), SwiftLint/swiftformat + py/sh/nix/yaml lint, CI (ci.yml, lint.yml, codeql.yml, secret-scan.yml). Existing MapQuizRegionHelperTests.swift covers the target. No setup stories prepended.

## 2026-06-17 — Story loop: 001-clamp-quiz-region DONE
- Implemented bounding-box-centered, all-pins-visible region with clamped jitter, latitude + portrait-aspect correction, and banner inset budget in MapQuizRegionHelper.swift.
- Covers both call sites (MapQuizSession/MapQuizView and MapLearningSession/MapLearningQuizView) via the unchanged makeQuizAnnotations signature.
- lint-swift clean; just test = TEST SUCCEEDED; region suite 13/13 pass.

## 2026-06-17 — create-pr: DONE
- Pushed feat/map-quiz-next-question-zoom; opened PR #93 vs main.

## 2026-06-17 — wait-for-ci: PASS
- PR #93: Build & Test pass, Lint pass, Detect-changes pass, gitleaks pass. (CodeQL/secret-scan are scheduled, not per-PR, per project convention.)

## 2026-06-17 — verify-feature: DONE
- Acceptance criteria are encoded as deterministic unit tests asserting all pins inside the banner-/aspect-adjusted visible rect across: representative European spread, every jitter axis-corner, wide horizontal spread on portrait, wide spread at high latitude, bounding-box-centered center, single pin, coincident pins, and 200 randomized full makeQuizAnnotations draws. All pass. Both call sites (MapQuizView, MapLearningQuizView) covered via shared makeQuizAnnotations.

## 2026-06-17 — evaluate-workflow: DONE
Telemetry outliers: no live telemetry captured this run; cross-run history (7 dates, 329 runs) shows implement-story as the retry outlier (38 notes / 46 runs).
Permission remediation: none this run — no permissions capture file present (graceful no-op).
Phase 2a flags: none — all 14 agent files OK; implement-story is long (99 lines) but each rule is a distinct project-specific guardrail.
Phase 2b: ran (>=2 dates). Prior recommendation (#92 lint-gate first-pass checklist on implement-story) WAS applied. Before/after fine-grained trend: Insufficient data in live view; qualitatively Supported — retries remain the top signal, so the checklist is the right lever.
Improvements: extended implement-story lint-first checklist with two recurring violations actually hit this run — line_length (>120 chars; break long XCTAssert/expr or hoist locals) and large_tuple (use a named struct for 3+ field returns instead of a 4-tuple).
