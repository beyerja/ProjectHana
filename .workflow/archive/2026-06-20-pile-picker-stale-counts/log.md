# Workflow log — pile-picker-stale-counts

Feature: PilePickerView new/pending counts stay stale after returning from a quiz.
Follow-up to PR #114 (Home/Stats stale-count fix). Same Observation gap; apply the
established `revision`-dependency pattern.

## Step 1 — Clarify
- Skipped engaging the user: root cause is unambiguous (confirmed via codebase
  investigation) and the report itself supplied full context. Wrote finalized spec
  directly to .workflow/feature.md.

## Step 0 — Worktree setup
- Slug: `pile-picker-stale-counts`
- HANA_FEATURE_SLUG=pile-picker-stale-counts
- Decision: WORKTREE created (feature touches app code only, not workflow tooling).
- Worktree: ../ProjectHana-worktrees/pile-picker-stale-counts
- Branch: feat/pile-picker-stale-counts (based on origin/main @ 4cc095a, includes #114 fix)
- direnv allow: OK
- Pre-investigation: target view confirmed as Hanahuac/Views/Home/PilePickerView.swift.
  Derives newCount/pendingCount from cardStore.newCards(for:)/dueCards(for:) fetch
  accessors and never reads `cardStore.revision` in body → same gap fixed in HomeView
  (which now does `_ = cardStore.revision` in body). Clarification deemed unnecessary.

2026-06-20 break-stories: DONE, 1 story
2026-06-20 assess-project-health: DONE — none
2026-06-20 story 001-pile-picker-revision-dependency: DONE
  - PR #121 -> main, squash-merged as 7793b74 (main advanced 4cc095a..7793b74)
  - Change: PilePickerView.body now reads `_ = cardStore.revision` (mirrors #114 HomeView)
  - Added regression test in CardStoreTests.swift
  - just lint + just test green; independent-review APPROVED round 1; verify-story DONE
2026-06-20 Step 5 (feature PR): N/A — single story already opened+merged PR #121 to main.
  Feature code is on main; no separate feature-level PR needed.
2026-06-20 Step 6 (wait-for-ci): satisfied within story (PR #121 CI PASS before squash-merge).
2026-06-20 verify-feature: DONE
2026-06-20 evaluate-workflow: DONE
Telemetry outliers: implement-story (highest avg duration/retries — expected, the heaviest phase), verify-feature (12.8m avg — verification fan-out, not ambiguity). No actionable over-read outlier this run.
Permission remediation: distribution: cd <pile-picker-worktree>:5 (all `cd … && grep/find` inspection or `cd … && just log`, i.e. noise — violates Grep/Glob + path-flag rules already in CLAUDE.md), gh beyerja/ProjectHana / git -C / just -f (already-canonical path-flag shapes). No clean recurring workflow command to allowlist; applied: none; proposed: none (capture file is shared across all of today's parallel runs; pile-picker footprint is inspection noise).
Phase 2a flags: none (all agent files OK; long files are dense project-specific guardrails, each rule earning its place).
Phase 2b: 9 distinct dates. Applied-edit detection: #117 (story-workflow + independent-review reply-resolve wording) and #106 (implement-story SwiftData / orchestrator main-integration) both applied and present. Qualitative: #106 "integrate main before PR; re-integrate if DIRTY" — Supported, but this run surfaced the adjacent BEHIND (clean-but-stale) case the DIRTY guidance did not cover → addressed via merge-pr edit below.
Improvements:
- merge-pr.md: handle PR going BEHIND base (parallel worktrees advance main between CI-pass and merge) via `gh pr update-branch`; distinguish BEHIND (fast-forward) from DIRTY (conflict). This run had to do it manually.
- feature_orchestrator.md (Step 1): sanction skipping clarify-feature when the request already supplies unambiguous goal + acceptance criteria + root cause (e.g. a bug report naming the view + established fix pattern), writing feature.md directly and logging why. This run did it ad hoc.
- NOT changed: transient simctl PATH flake + concurrent-xcodebuild derived-data DB-lock — one-run transient infra flake, not reproducible agent behavior; adding guidance would be speculative.
