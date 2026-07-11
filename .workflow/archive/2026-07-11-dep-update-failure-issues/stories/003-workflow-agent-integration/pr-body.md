## Goal

Teach the workflow agents to self-heal dependency-update failures: every future feature-workflow run checks for the open rolling issue labeled `dep-update-failure` (created by the Story 002 monitor), comments that the run will take care of it, and folds the fix into the run's scope. Markdown-only changes to agent files in `.claude/agents/` — no app code, no `.github/` changes.

## Changes

- `feature-orchestrator.md`: early step (alongside the existing triage-dep-prs step) that lists open `dep-update-failure` issues via `gh -R beyerja/ProjectHana issue list --label dep-update-failure --state open --json number,title,url`; if one exists, comments on it (Write-tool-authored file + `--body-file`), records the issue number/URL in `.workflow/log.md`, and passes the fix into workflow scope (context for clarify-feature/break-stories or a prepended story).
- `triage-dep-prs.md`: extended to perform the same issue check as part of triage — for each failed run URL reported in the issue, diagnose with `gh run view <id> --log-failed` and fix what it can; close the issue with a summary comment when all reported failures are resolved, otherwise leave it open with a status comment describing what remains.
- Explicit no-issue path in both agents: when no open `dep-update-failure` issue exists, log that and continue with no comment or scope change.
- All added instructions use allowlistable command shapes per CLAUDE.md (`gh -R`, `--body-file`/`--comment-file` with Write-tool-authored files; no heredocs, no `cd &&`, no poll loops). Also consumes the flake.lock branch-push handoff introduced in #225.

## Test plan

- [ ] Diff is surgical: only the new step/extension in `feature-orchestrator.md` and `triage-dep-prs.md`; no unrelated sections reworded or reordered.
- [ ] New instructions in both agents contain only allowlist-friendly command shapes (no `$(…)`, heredocs, `cd &&`, or loops).
- [ ] No-issue path is explicit in both agents.
- [ ] CI passes (markdown-only change; no Xcode build impact).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
