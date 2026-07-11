# Workflow log — safe-stable-releases

Feature request: Prepare safe and stable releases for eventual App Store distribution.
No paid Apple Developer account yet: signing / App Store Connect / TestFlight / notarization
execution is out of scope; pipeline, versioning scheme, configuration, and documentation
preparation IS in scope.

Slug: `safe-stable-releases`
Worktree: `/Users/Private/Documents/Code/ProjectHana-worktrees/safe-stable-releases`
Branch: `feat/safe-stable-releases` (cut from main @ b034573)

## Phase transitions

- 2026-07-03 — STEP 0 START: worktree created at `../ProjectHana-worktrees/safe-stable-releases`, branch `feat/safe-stable-releases`, direnv allowed. Fresh run (no prior worktree for this slug).
- 2026-07-03 — STEP 1 (triage dep PRs): `triage-dep-prs` spawned. One open dep PR found: #160 (actions/checkout 6 -> 7), all CI checks green. Agent asked to complete gate + squash-merge. Awaiting final MERGED/SKIPPED report.
- 2026-07-03 — STEP 2 (clarify): `clarify-feature` spawned; user unavailable for Q&A, so agent instructed to document assumptions in `.workflow/feature.md` instead of asking.
- 2026-07-03 clarify-feature: DONE — spec written to `.workflow/feature.md` (repo-grounded: project.yml versioning, CI split, unsigned-build conventions verified). 9 documented assumptions in lieu of user Q&A.
- 2026-07-03 — STEP 1 COMPLETE: dep PR #160 (actions/checkout 6→7) MERGED (merge commit a0f3c59) after update-branch + green CI + code-owner-review gate on final SHA 778a440f. No other open dep PRs, no skips.
- 2026-07-03 — STEP 1 post-merge: worktree branch fast-forwarded to origin/main @ a0f3c59 (checkout v7 bumps integrated).
- 2026-07-03 — STEP 3 START: spawning `break-stories`.
- 2026-07-03 break-stories: DONE, 5 stories
- 2026-07-03 — NOTE for evaluate-workflow: triage-dep-prs detection jq is buggy — `.labels[].name == "dependencies"` poisons the `or` on empty labels, and `contains("[bot]")` misses login `app/dependabot`. Suggested fix: `(.author.is_bot == true or (.author.login | test("\\[bot\\]|^app/")))` and `((.labels | map(.name) | index("dependencies")) != null or ...)`. Initially caused a false "no dep PRs found".
- 2026-07-03 — STEP 4 START: spawning `assess-project-health`.
- 2026-07-03 assess-project-health: DONE — none (existing lint/test/CI bar already covers every file type and tool the 5 release stories add; no setup stories prepended)
- 2026-07-03 — STEP 5 START (story loop): spawning `story-workflow` for 001-versioning-bump-tooling.
- 2026-07-04 — STORY 001 DONE: PR #220 squash-merged to main as 64bf949; CI green, independent review + code-owner-review approved, all 6 acceptance criteria verified. Worktree branch even with origin/main @ 64bf949.
- 2026-07-04 — STORY 002 START: spawning `story-workflow` for 002-changelog-and-consistency-checks.
- 2026-07-04 — STORY 002 interrupted mid-review by session token limit; resumed at review step (PR #223 open, CI green, no review posted). Fresh independent-review: APPROVED.
- 2026-07-04 — STORY 002 gate: code-owner-review APPROVED, check posted on ae00827; PR BEHIND → update-branch → new head f71d1c9 → CI green → gate re-posted (check-run 85149272051) → squash-merged as 0f46af2, branch deleted.
- 2026-07-04 — STORY 002 DONE: verify-story PASS on all 6 criteria (36/36 script tests, live positive+negative checks, lint green, zero .github changes). status.md=done.
- 2026-07-04 — STORY 003 START: spawning `story-workflow` for 003-unsigned-archive-proof-local-tooling.
- 2026-07-05 — STORY 003 DONE: PR #228 squash-merged as 3b555ca. PROVEN: unsigned iOS device Release archive works (generic/platform=iOS, CODE_SIGNING_ALLOWED=NO) — no Catalyst fallback needed; unsigned .ipa feasible via scripts/package-ipa.sh. Delivered: `just archive`, `just release-check [tag]`, `test-mac`, `build-mac-release`. Proof record in story log (binding for 004/005). Deviation for 005 docs: `test-mac` locally skips HanahuacUITests (deterministic local Catalyst runner hang; CI still runs them). Worktree synced to main.
- 2026-07-05 — STORY 004 START: spawning `story-workflow` for 004-release-workflow.
- 2026-07-06/07 — STORY 004: two session-token-limit interruptions (mid-lifecycle and mid-merge); orchestrator drove children directly (implement → create-pr → wait-for-ci → independent-review → code-owner-review → merge-pr). One CI failure: actionlint rejected secrets context in step if: expressions (fix 546b11e: credential-detect step routing secrets via env). PR #232 squash-merged as e50d0ac; both review gates passed on 546b11e (gate check-run 86409744089).
- 2026-07-07 — STORY 004 DONE: verify-story PASS on all 9 criteria (lint incl. actionlint green, 58/58 release-script assertions, zero per-PR CI diff, action versions verified empirically). Process lesson recorded: re-run `just lint` after every workflow-file edit before commit.
- 2026-07-07 — STORY 005 START: spawning `story-workflow` for 005-releasing-docs-dry-run.
- 2026-07-10 — STORY 005: lifecycle completed across a token-limit interruption. PR #234 squash-merged as c65ac60 (docs/releasing.md runbook + README pointer). Dry-run of release.yml GREEN on first attempt (run 29126126066, workflow_dispatch dry_run=true, gates job success, publish correctly skipped).
- 2026-07-11 — STORY 005 DONE: verify-story PASS on all 6 criteria (runbook complete incl. switch-on section with exact secret names; dry-run re-verified via API; lint green; docs-only diff). All 5 stories done.
- 2026-07-11 — STEP 6 (create PR): EXPECTED PATH — every story merged incrementally to main via its own PR; `feat/safe-stable-releases` is an ancestor of origin/main (verified via merge-base --is-ancestor). No unmerged feature-branch commits → no separate feature PR. STEP 7 (wait-for-ci) not applicable.
- 2026-07-11 — STEP 8 START: spawning `verify-feature`.
- 2026-07-11 verify-feature: DONE — all 11 acceptance criteria verified against origin/main c65ac60 (worktree synced, clean). Evidence per criterion: (1) version only in project.yml (1.0.0/build 1); `just bump bogus` rejected (exit 2), `just bump patch` produced clean 2-file diff (project.yml 2 lines + regenerated pbxproj) → reverted. (2) CHANGELOG.md Keep-a-Changelog with [Unreleased] + seeded 1.0.0 summary. (3) release.yml triggers = v* tag push + workflow_dispatch(dry_run) only; gates ordered a→g, each fail-on-violation. (4) unsigned .xcarchive.zip + .ipa + SHA256SUMS produced in dry-run (real checksums in log); Release attach via gh --notes-file+--generate-notes+--verify-tag, prerelease on '-' suffix (gh flag combo empirically verified in story 004). (5) ASC/TestFlight placeholders gated on APPSTORE_UPLOAD_ENABLED var + 3 APP_STORE_CONNECT_* secrets with explicit skip-explain step. (6) dry-run 29126126066 GREEN (success, workflow_dispatch, main@0303bc3 = ancestor of c65ac60; release.yml/scripts/justfile unchanged since); anti-vacuous check: gate (d) executed 553+ tests TEST SUCCEEDED, gate (a) skipped-with-explanation as designed, publish job skipped. (7) `just release-check` (6 steps) + `just archive` (emits archive/.ipa paths) exist; both re-run green on merged main in story-003 verify + re-exercised in CI dry-run; check-changelog/check-tag-version pass v1.0.0 and correctly fail v9.9.9. (8) zero per-PR blocking changes by this feature: ci/lint/secret-scan diffs vs b034573 come only from PR #221 (different workflow) + Dependabot #160; no trigger changes; release.yml has no pull_request trigger. (9) docs/releasing.md complete: versioning, runbook, gates table, switch-on section (exact secret names, project.yml signing settings, var flip, live-step map, re-verify-tooling note). (10) lint.yml green on main c65ac60 + gate (c) green in dry-run. (11) PR #232 body records empirical action-version table (checkout@v7, install-nix-action@v31, upload-artifact@v7, download-artifact@v8). STATUS: DONE.
- 2026-07-11 evaluate-workflow: DONE (completed after a session-token interruption; the interrupted
  attempt's uncommitted agent edits were reviewed hunk-by-hunk, one corrected, none reverted).
  Telemetry outliers: implement-story (avg 22.4k est-tokens, top consumer — lint-rerun rule targets its
  main retry cause), independent-review (12k avg; duration improved 7.5m→4.3m since the 07-05
  no-sub-agent pre-flight landed), story-workflow (38m avg — orchestration span, expected).
  Tool distribution (hooks, 07-03..07-11): Bash 2140 (avg 414 tok), Read 810 (avg 1416), Edit 275,
  Write 256, Agent 196.
  Permission remediation: distribution `gh beyerja/ProjectHana` (gh -R-first): 269, `git -C <primary>`:
  187, find/ls/grep inspection noise: ~150, gh-review-bot.sh wrapper: 27, cd-worktree compounds: 16,
  python3 heredocs: 14. Applied (shape fixes only — settings.json is a human action): -R moved after the
  gh pr subcommand in code-owner-review/independent-review (allowlist prefix-matches `gh pr <sub> …`);
  verify-feature fetch/show now uses `git -C <worktree> fetch` + plain `git show` (both allowlisted)
  instead of `git -C <primary>`. Proposed for the user (no edit): fix the wrapper allow entry —
  `Bash(scripts/gh-review-bot.sh:*)` does not match the actual `scripts/gh-review-bot.sh gh api …`
  invocations (27 prompts); and extend scripts/telemetry-summary.py with a hooks/permissions mode so
  future evaluations stop hand-rolling python3 heredocs (14 prompts).
  Finalized agent edits (uncommitted, for the closing chore PR):
  - story-workflow.md: log resumable ids (PR number, head SHA, run id) the moment they exist — this
    run survived 5+ token-limit interruptions because story logs carried them. (Foreground-children
    rule already present in story-workflow.md + feature_orchestrator.md from the 07-05 evaluation —
    not duplicated.)
  - triage-dep-prs.md: detection jq fixed per the 2026-07-03 note (`.labels[].name ==` poisons `or` on
    empty labels; `contains("[bot]")` misses `app/dependabot`) — fix validated against sample data;
    main's copy still had the bug (no duplicate).
  - implement-story.md: re-run `just lint` after the LAST edit, immediately before commit (story 004's
    actionlint CI failure: 6 errors shipped because a late workflow-file tweak was never re-linted).
  - independent-review.md + code-owner-review.md: `-R` after the `gh pr` subcommand (top-prompted gh
    shape, 269 prompts this run).
  - verify-feature.md: post-merge reads via allowlisted shapes (corrected from the interrupted attempt,
    which claimed plain `git fetch` was allowlisted — it is not; only `git -C <worktrees>/* fetch*` and
    plain `git show *` are).
  Not broken: merge-pr SHA-bound gate re-post untouched; empirical-verification rules untouched.
  Phase 2a flags: none (all 17 files OK — each rule maps to a distinct documented failure; sole nit:
  triage-dep-prs.md's two footer sections restate CLAUDE.md, proposed trim only, no edit).
  Phase 2b (21 distinct dates, boundary d65948d 2026-07-05): all 4 prior recommendations were applied
  in the same commit — none unapplied. independent-review Improved on duration (7.5m→4.3m, no re-spawn
  loops this run → claim Supported); code-owner-review duration Flat, est-tokens Regressed
  (2490→4235, confounded by the large release.yml diffs, n=10); break-stories + story-workflow
  Insufficient data. SHA-bound-gate claim Inconclusive post-edit (no update-branch case after 07-05;
  story 002 pre-edit executed the codified behavior correctly).
- 2026-07-11T20:22:12Z code-owner-review: APPROVED — closing-artifacts PR #237 independently re-verified
  (jq fix semantics traced, gitignore rule + gh reordering + agent-file prose checked, archive move clean;
  first reviewer's inline note non-blocking). `code-owner-review` check posted with conclusion success on
  head 7fd95f4 (check-run id 86581392852, app id 4144849, read-back verified). mergeStateStatus BEHIND —
  gate is SHA-bound; re-post on the new head after any update-branch.
