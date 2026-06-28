## Goal

Add a `triage-dep-prs` agent that automatically handles open Dependabot / Renovate PRs before feature story work begins, so stories always build on a clean, up-to-date `main`.

## Changes

- **`.claude/agents/triage-dep-prs.md` (new):** Self-contained sub-agent that:
  - Detects open dep PRs by filtering for `[bot]`-authored PRs with a `dependencies` label or a `dependabot/` / `renovate/` branch-name prefix
  - Resolves merge conflicts via rebase onto `main` (preserving version-bump changes in `Package.swift` / `Package.resolved`; preferring `main` for all other sides)
  - Runs `just lint` + `just test` locally before posting any gate check
  - Self-heals missing CI by closing/reopening the PR and waiting with `gh pr checks --watch --fail-fast`
  - Posts the `code-owner-review` success check via `scripts/gh-review-bot.sh` (App id `4144849`) and reads it back to confirm `app_id` and `conclusion`
  - Attempts a minimal call-site fix if tests fail after a rebase; skips the PR if the fix fails
  - Degrades gracefully when bot credentials are absent: posts a plain informational comment and records "gate check SKIPPED" in `.workflow/log.md`
  - Squash-merges each qualifying PR with `gh pr merge --squash --delete-branch`
  - Collects skipped PRs and surfaces them prominently in the final STATUS output
  - Complies with CLAUDE.md rules: all git ops use `-C <path>`, commit messages use `git commit -F <file>`, no heredocs or `$(...)` payloads, no poll loops

- **`.claude/agents/feature_orchestrator.md` (updated):** Wires `triage-dep-prs` as Step 1 (before `clarify-feature`), with a `git fetch origin && git merge origin/main` after triage completes so the worktree sees all freshly-merged dep changes before any story work begins. Skipped dep PRs are noted in `.workflow/log.md` and never block feature stories.

## Test plan

- [ ] Confirm `.claude/agents/triage-dep-prs.md` exists and has frontmatter `name: triage-dep-prs`
- [ ] Review detection query covers `[bot]` login + `dependencies` label OR `dependabot/` / `renovate/` branch prefix
- [ ] Verify "no dep PRs" early-exit path is documented (log + STATUS: DONE, no branch or check ops)
- [ ] Verify conflict-resolution logic: `--theirs` for `Package.swift` / `Package.resolved`, `--ours` for everything else
- [ ] Confirm gate check is only posted after `just lint` + `just test` pass
- [ ] Confirm check read-back asserts `app_id == 4144849`
- [ ] Verify CI self-heal uses `gh pr close` + `gh pr reopen` (no poll loop) and falls back to an empty commit
- [ ] Verify graceful degradation path: informational comment + "gate check SKIPPED" log entry + PR added to skipped list
- [ ] Confirm `feature_orchestrator.md` Step 1 spawns `triage-dep-prs` and runs `git merge origin/main` afterward
- [ ] Check all git commands use `-C <path>`, no `cd &&` compounds, no heredocs

🤖 Generated with [Claude Code](https://claude.com/claude-code)
