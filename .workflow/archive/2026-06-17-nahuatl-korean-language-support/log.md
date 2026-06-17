# Workflow log — nahuatl-korean-language-support

## Step 0 — Worktree setup
- Feature slug: `nahuatl-korean-language-support`
- Decision: **worktree** (feature change, not workflow tooling). Reused pre-existing worktree at
  `../ProjectHana-worktrees/nahuatl-korean-language-support` on branch `feat/nahuatl-korean-language-support`
  (created by a prior run as agent ab3491975176daa43; clean, at main HEAD 6c99b84).
- `HANA_FEATURE_SLUG=nahuatl-korean-language-support`
- Ran `direnv allow` in the worktree before any `just` call.

## Step 1 — Clarify
- Clarifying questions already answered by the user (provided in this run's prompt). Skipping a
  fresh `clarify-feature` spawn; writing the spec directly to `.workflow/feature.md` from the
  confirmed answers:
  - Languages: Korean (`ko`) + generic Nahuatl (`nah`).
  - Scope: UI strings + geographic content for both.
  - Quality: best-effort self-generated translations; fallback chain = new language → Mexican
    Spanish (es-MX / nameEs) → English (NOT English-first).
  - Display names: "한국어" and "Nāhuatl".
  - Auto-detection: detect from device locale, manual override allowed (same as existing langs).
  - Non-goals: none beyond implied.

## Step 2 — Break stories
2026-06-17 break-stories: DONE, 3 stories (001-applocale-and-fallback, 002-ui-strings, 003-geographic-content)

## Step 3 — Assess project health
2026-06-17 assess-project-health: DONE — none. Project already has SwiftLint + swiftformat, shellcheck, ruff, nixfmt, yaml lint, xcodebuild test suite, and CI. Noted project uses xcodegen (project.yml -> just generate); updated story 001 to edit project.yml not pbxproj. No setup stories prepended.

## Step 4 — Story loop
2026-06-17 story-workflow 001-applocale-and-fallback: START
2026-06-17 story-workflow 001-applocale-and-fallback: DONE — PR #94 merged (squash, admin), CI green.
2026-06-17 story-workflow 002-ui-strings: DONE — PR #96 merged, CI green. Korean full, Nahuatl partial (es-MX fallback).
2026-06-17 story-workflow 003-geographic-content: DONE — PR #97 merged, CI green. All 3 stories complete.

## Step 7 — Verify feature
2026-06-17 verify-feature: DONE — full suite green on merged main; app launches cleanly with new locales registered + 197-country data decoding (home renders es-MX baseline). Korean/Nahuatl runtime resolution proven by L10nBundleResolutionTests (ko→Korean, nah-missing→es-MX, never raw key). Picker enumeration + display names covered by AppLocaleTests. Visual locale-switch screenshot blocked by cfprefsd caching of the sandboxed default (harness limitation), so verified via bundle-backed runtime tests per verify-feature guidance.

## Step 8 — Evaluate workflow
2026-06-17 evaluate-workflow: DONE
Telemetry outliers: implement-story (avg 6.2m, 11 notes — highest; this run's note was
  "explicit-memberwise-inits-for-source-compat", a Codable-field compile gotcha) and verify-feature
  (6.3m, 5 notes). story-workflow longest wall-clock (8.3m) as expected (it nests the others).
Permission remediation: distribution dominated by "cd /…/ProjectHana-worktrees/<slug>" (108/153),
  the known injectable cd-compound signature the orchestrator already warns against — cannot be
  auto-allowlisted (security bar: no Bash(cd *)). Remaining records all inspection noise
  (ls/cat/grep/find/echo/bare git). No recurring safe workflow command to wrap. No allowlist edit.
Phase 2a flags: none — all 15 agent files are dense project-specific guardrails, no genuine bloat.
Phase 2b: ran (7 distinct dates). Prior recommendations consistently applied (#92 lint checklist,
  #90 direnv, #82/#75 archives). #92's lint-checklist claim is Supported — zero lint retries this run.
Improvements: added a guardrail to implement-story.md (primary checkout) — when adding a field to a
  plain Codable struct, write an explicit memberwise init defaulting the new field(s) rather than
  editing every call site (the one friction point this run).
