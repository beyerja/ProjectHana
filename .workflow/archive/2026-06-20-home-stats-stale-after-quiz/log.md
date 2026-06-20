# Workflow log — home-stats-stale-after-quiz

Feature slug: `home-stats-stale-after-quiz`
Bug report: Home/main screen numbers (stats/scores/progress) are stale after completing a quiz — they retain old values until some other refresh occurs.

## Step 0 — Worktree setup
- Created worktree at `../ProjectHana-worktrees/home-stats-stale-after-quiz` on branch `feat/home-stats-stale-after-quiz` from `main`.
- direnv allowed.
- Isolation: worktree (touches app code, not workflow tooling).
- HANA_FEATURE_SLUG=home-stats-stale-after-quiz

## Step 1 — Clarify
- Clarify investigation + user answers supplied by orchestrator (not re-asked).
- Root cause confirmed by reading code: HomeView/StatsView derive all numbers from CardStore/ProgressStatsStore fetch accessors that read no @Observable stored property, so SwiftUI registers no dependency and never invalidates after quiz-driven SwiftData mutations. Recovery only on relaunch / subtree rebuild.
- User answers: (1) BOTH home pills + Progress numbers stale; (2) only relaunch confirmed as recovery; (3) all quiz types/categories assumed; (4) must update immediately, no relaunch.
- Wrote finalized spec to .workflow/feature.md.
- Outcome: DONE.

## Step 2 — Break stories
2026-06-20 break-stories: DONE, 2 stories

## Step 3 — Assess health
2026-06-20 assess-project-health: DONE — none. Mature repo with complete quality infrastructure; no setup stories prepended. Verified: `just test` (xcodebuild test + HanahuacTests/ + CI Build & Test job); `just lint` covering Swift (SwiftLint --strict + swiftformat), Python (Ruff), shell (shellcheck), Nix (nixfmt), YAML (yamllint), each with a committed config; type-checking via Swift compiler in build/test; CI workflows ci.yml/lint.yml/codeql.yml/secret-scan.yml plus dependabot and flake-lock automation. No gaps found.

## Step 4 — Story loop
- Story 001 (store revision signal + view dependency): implemented, PR #110 squash-merged into feat branch, verified DONE.
- Story 002 (route graded-card saves through bumping store method): audit found quiz sessions rely on SwiftData autosave (no bare save()); learning views (LearningQuizView, MapLearningQuizView) bumped nothing. Added CardStore.persistCardChanges() called after every grade in all 6 quiz views; learning views now inject CardStore. PR #113 squash-merged into feat branch, verified DONE.

## Step 5 — Integrate main + create feature PR
- Fetched origin; main advanced by #111 (independent-review agent, .claude/agents/ only — no app-code conflict). Merged origin/main cleanly into feat branch.
- Re-ran `just lint` (passed) + `just test` (TEST SUCCEEDED) post-integration.

2026-06-20 13:50:29 +0200 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/114

## Step 6 — Verify feature
2026-06-20 verify-feature: DONE — all 7 acceptance criteria satisfied. Stores expose private(set) revision bumped via markChanged() on every save path (upsert, recordSnapshot, resetAll, seedIfNeeded, deduplicate, persistCardChanges, ensureGraduationConsistency). HomeView/StatsView read revision at top of body before fetches (HomeView keeps .id(languageManager.current) — no language regression). All 6 quiz views (MultipleChoice, MapQuiz, MapLearning, Learning, Capital, NameFeature) call cardStore.persistCardChanges() after each grade/advance; the 2 learning views inject CardStore via @Environment. Per-grade persistence covers early-exit (state up to last graded card is already flushed). Tests prove revision fires on card mutation (upsert/persistCardChanges/resetAll/seed/dedup) and snapshot recording (recordSnapshot/dedup), incl. a flush-correctness test. just lint passed; just test TEST SUCCEEDED; CI green on clean store/build (PR #114). Visual: app launches without crash, HomeView renders New/Pending pills + Settings gear entry point; deeper dynamic refresh verified via unit tests + code (no tap automation available).

## Step 7 — Merge feature PR
2026-06-20 merge-pr: DONE — PR #114 squash-merged into main (merge commit 4f630b80e5750c677d97c397b9d310f068975ffd), remote branch feat/home-stats-stale-after-quiz deleted. Branch was behind base; ran update-branch, CI re-ran green (Build & Test, Lint, gitleaks, Detect changes), then merged. Stories 001 + 002 status -> merged. Primary checkout on feat/independent-pr-review (not main): fetched origin only, no checkout/merge per worktree rules.
