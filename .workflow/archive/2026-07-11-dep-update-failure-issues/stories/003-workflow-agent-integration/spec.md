# Story 003 — workflow agent integration

## Title
Teach feature-orchestrator and triage-dep-prs to pick up open `dep-update-failure` issues

## Goal
Adjust the workflow agents so every future feature-workflow run self-heals dependency-update
failures: at workflow start, check for open issues labeled `dep-update-failure`; if found,
comment on the issue that this run will take care of it, and include the fix in the run's scope.

## Context

- Files to change (markdown only, in `.claude/agents/`): `feature-orchestrator.md` and
  `triage-dep-prs.md`. **No app code, no `.github/` changes, no Xcode build needed.**
- The `dep-update-failure` issue convention comes from Story 002: a single rolling open issue
  labeled `dep-update-failure`, title marker `[dep-update-failure]`, body/comments listing
  failed run URLs of the dependency-update automations ("Update flake.lock",
  "Dependabot Updates").
- triage-dep-prs already runs as an early step of feature-orchestrator (Step 1), so the issue
  check naturally slots in alongside it.
- Editing scope caution: these agent files are also touched by evaluate-workflow; make surgical
  insertions, do not restructure unrelated sections.

**Command shapes for the instructions being added (allowlist-friendly, per CLAUDE.md):**
- Find issue: `gh -R beyerja/ProjectHana issue list --label dep-update-failure --state open
  --json number,title,url`
- Comment: write the comment text to a file with the Write tool, then
  `gh -R beyerja/ProjectHana issue comment <n> --body-file <file>` (no `--body "$(…)"`).
- Close with summary: write summary to a file, then
  `gh -R beyerja/ProjectHana issue close <n> --comment-file <file>` (or comment then close).

## Acceptance Criteria

- [ ] `feature-orchestrator.md` gains an early step (alongside the existing triage-dep-prs
      step) instructing the orchestrator to check for open issues labeled `dep-update-failure`;
      if any exist: (a) comment on the issue that this workflow run will take care of it,
      (b) record the issue number/URL in `.workflow/log.md`, and (c) include the fix in the
      workflow scope — passed as context to clarify-feature/break-stories or prepended as a
      story.
- [ ] `triage-dep-prs.md` is extended to perform the same issue check as part of triage:
      for each failed run URL reported in the issue, diagnose it (`gh run view <id>
      --log-failed`), fix what it can, and on completion close the issue with a summary
      comment when all reported failures are resolved — or leave it open with a status
      comment describing what remains and why.
- [ ] Both agents' new instructions use allowlistable command shapes (`gh -R`, `--body-file`
      with Write-tool-authored files; no heredocs, no `cd &&`, no poll loops).
- [ ] The no-issue path is explicit in both agents: when no open `dep-update-failure` issue
      exists, log that and continue without any comment or scope change.
- [ ] The added instructions are surgical: no unrelated sections of either agent file are
      reworded or reordered (diff limited to the new step/extension).
