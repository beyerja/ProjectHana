# Workflow Log — per-quiz-type-progress

Feature request: Progress should be tracked separately per quiz type (e.g. Map Tab Quiz vs. Multiple Choice quiz) within one category, instead of all quizzes of a category sharing the same underlying progress. Analogous to the recently-added per-language dimension.

Slug: `per-quiz-type-progress`

## Phase transitions

- **Step 0 — Worktree setup**: Created worktree at `../ProjectHana-worktrees/per-quiz-type-progress` on branch `feat/per-quiz-type-progress` from `main`. `direnv allow` run. This is a feature run (not tooling/meta), so a worktree is used. `HANA_FEATURE_SLUG=per-quiz-type-progress`.
- **Resume (2026-06-20)**: Orchestrator resumed. Integrated latest `origin/main` (4cc095a) into the feature branch (clean merge, no conflicts). Clarification already FINAL (user provided answers). Wrote `.workflow/feature.md` with the finalized per-quiz-type-progress spec (quizMode as orthogonal 2nd dimension; identity `(factID, language, quizMode)`; mapQuiz migration target; per-mode active set; shared per-language streak; aggregated stats + per-mode breakdown toggle; SchemaV3).
- **Step 1 — Clarify**: spec VALIDATED (answers final); `.workflow/feature.md` written. DONE.
- **Step 2 — Break stories**: DONE — 6 stories mirroring the per-language structure: 001 model+SchemaV3, 002 CardStore (language,quizMode) scoping + provider, 003 per-mode snapshots (aggregated default preserved), 004 per-mode active set, 005 legacy→mapQuiz migration, 006 stats per-mode breakdown toggle. Streak stays per-language/shared (guard-tested in 003/005). Build stays green per-commit (001 is additive-only).
- **Step 4 — Story loop**:
  - **001-reviewcard-quizmode-dimension**: DONE & merged (PR #122). Additive model+SchemaV3 foundation. CI retrigger needed an empty commit (force-push blocked under auto mode; merge commits w/o build-relevant diff don't retrigger). Verified on clean sim.
  - **002-cardstore-quizmode-scoping**: DONE & merged (PR #125). CardStore (language,quizMode) scoping + CardStoreProvider vended per mode; threaded through all views. Review APPROVED with a non-blocking follow-up recorded into Story 003's spec (aggregate snapshot must use provider.allCards). Live sim launch confirms each mode shows independent counts. Rebased onto main before pushing → CI triggered normally (no empty-commit dance needed).
  - **003-snapshot-per-mode-recording**: DONE & merged (PR #127). ProgressStatsStore keyed by (day,language,quizMode); dual-write records aggregate (cross-mode union) + per-mode rows; fixed the #125 aggregate-undercount. Review APPROVED; recorded a cross-story correction into Story 005's spec (legacy DailyProgressSnapshot rows must STAY aggregate `""`, only ReviewCard rows get stamped mapQuiz). Verified on integrated branch.
  - **004-activeset-per-mode**: DONE & merged (PR #128). activeSetKey namespaced (language,mode,category); mode threaded with nil-default (legacy per-language key preserved as Story-005 migration source). Review APPROVED. Verified on integrated branch.
  - **005-migration-legacy-to-mapquiz**: DONE & merged (PR #129). Per-quiz-mode migration step (own flag) stamps empty-quizMode ReviewCards mapQuiz, leaves DailyProgressSnapshot aggregate, copies legacy per-language active set → mapQuiz key. Updated one existing per-language migration test for the new end-state. Review APPROVED. Verified on clean sim.
  - **006-stats-ui-mode-breakdown**: DONE & merged (PR #130). ModeProgressSummary + StatsView per-mode breakdown toggle (collapsed default → aggregated view unchanged); stats.by_mode localized. Review APPROVED. Verified.
- **Step 5/6 — Feature PR + CI**: N/A as a separate PR — all 6 story PRs targeted `main` directly and are squash-merged, so `feat/per-quiz-type-progress` == `origin/main` (0 ahead / 0 behind, empty source diff). The feature is fully integrated into main; each story already passed CI + independent review + merge. No separate feature PR/CI step required.
- **Step 7 — Verify feature**: DONE. All 9 acceptance criteria satisfied:
  1. ReviewCard `quizMode` defaulted; identity/dedup `(factID,language,quizMode)`; two modes coexist for same fact — QuizModeDimensionTests. ✓
  2. Each mode via CardStore scoped `(language,quizMode)`; grading one mode leaves others untouched — PerQuizModeProgressTests. ✓
  3. One-time idempotent migration → mapQuiz; others empty; re-run safe — PerQuizModeMigratorTests. ✓
  4. ActiveSetStore namespaced `(language,mode,category)`; per-mode advance independent — PerModeActiveSetTests. ✓
  5. StreakTracker per-language, shared across modes — PerModeSnapshotTests.testStreakIsSharedAcrossModes. ✓
  6. Progress default mode-aggregated + per-mode breakdown toggle; per-mode snapshots recorded — PerModeSnapshotTests + ModeProgressSummaryTests. ✓
  7. typeCapital Countries-only — servedCategories + PerQuizModeProgressTests.testTypeCapitalStoreIsCountriesOnly. ✓
  8. Head schema SchemaV3, additive lightweight CloudKit-safe migration; sync readiness preserved. ✓
  9. Full test suite green in CI across all 6 story PRs. ✓
  Visual: clean-store launch shows independent per-mode counts (.workflow/screenshots/feature-verify.png); per-mode breakdown section compiles into the bundle + is unit-tested + mirrors the proven per-language breakdown (no tap automation available to open the Progress screen). `just install` updated the local app (progress preserved). STATUS: DONE.
- **Step 8 — Evaluate workflow**: DONE.
  Telemetry outliers: live telemetry absent this run (orchestrator ran the lifecycle directly without per-sub-agent telemetry hooks; no `.workflow/telemetry/` in this worktree — the sink lives in the primary checkout). Cross-run history via `just telemetry-history`: 854 runs / 9 dates. Top outlier remains `implement-story` (108 runs, 100 retry/notes) → implementation friction; `evaluate-workflow` highest avg est tokens (4377).
  Permission remediation: none this run — no `permissions-*.jsonl` captured in this worktree (orchestrator session, hooks write to the primary sink). Skipping.
  Phase 2a flags: none — agent files are tightly-scoped guardrails; the two edits below add distinct real-failure rules, not bloat.
  Phase 2b: history ≥2 dates so eligible. Applied-edit detection: agent files actively maintained (#92 lint checklist, #107 command-shape docs, #115 independent-review). `implement-story` retry/notes still high (100/108) — predominantly telemetry note payloads, not all failures; no isolated before/after window to attribute a clean trend, so reported as Inconclusive rather than fabricating one.
  Improvements applied (2, surgical, grounded in THIS run's friction):
    1. implement-story: guard against overloaded `foo(for:)` methods taking two different enums with shared case names — they make leading-dot call sites `ambiguous`; use distinct labels (`store(for:)` vs `store(forModeID:)`). [Real compile failure hit in Story 002.]
    2. create-pr: rebase the story branch onto `origin/main` BEFORE the first push (linear rebase > merge — a merge commit with no build-relevant diff doesn't retrigger pull_request CI, leaving the PR BLOCKED with no checks; force-push is blocked under Auto, so once pushed prefer merge+push and an empty-commit nudge only if no CI run fires). [Story-001 CI-retrigger churn; rebasing fixed it for Stories 002-006.]
- **Step 3 — Assess health**: DONE — no gaps. Project already has full quality infra (`just test` on sim, `just lint` = swift/py/sh/nix/yaml, CI workflows, xcodegen `just generate`, per-worktree DerivedData isolation via `wt`). No setup stories prepended (matches the per-language precedent). Establishing a green baseline build before the story loop.
