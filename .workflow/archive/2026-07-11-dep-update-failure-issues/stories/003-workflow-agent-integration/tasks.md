# Tasks — Story 003: workflow agent integration

Markdown-only story. Files live in `.claude/agents/` in the worktree
`/Users/Private/Documents/Code/ProjectHana-worktrees/dep-update-failure-issues`.
NOTE: the orchestrator file on disk is **`feature_orchestrator.md`** (underscore), frontmatter
name `feature-orchestrator`. Edits must be surgical insertions — evaluate-workflow also touches
these files; do not reword or reorder unrelated sections.

## Tasks
- [x] 001: `feature_orchestrator.md` — insert a dep-update-failure issue check into Step 1
      (alongside the existing triage-dep-prs sub-bullets, as an additional bullet block; do not
      renumber or reword surrounding steps). The new text instructs the orchestrator to:
      (a) run `gh -R beyerja/ProjectHana issue list --label dep-update-failure --state open --json number,title,url`
          and the same with `--label flake-lock-update`;
      (b) if issues are found: write a comment body via the Write tool ("this workflow run will
          take care of it"), post with `gh -R beyerja/ProjectHana issue comment <n> --body-file <file>`,
          record issue number/URL in `.workflow/log.md` (Edit tool append), and include the fix in
          the workflow scope — passed as context to clarify-feature/break-stories or prepended as
          a story;
      (c) explicit no-issue path: when neither label has open issues, append a "no open
          dep-update-failure / flake-lock-update issues" line to `.workflow/log.md` and continue
          with no comment and no scope change.
      Do NOT re-add a "tooling edits take effect on merge" note — Step 0 item 2 already states it;
      the new bullet may reference that existing note in one clause at most.
- [x] 002: `triage-dep-prs.md` — extend triage with issue diagnosis. Insert a new section (after
      Step 1, before Step 2; keep existing step numbering intact, e.g. "Step 1b") that:
      (a) lists open issues: `gh -R <owner/repo> issue list --label dep-update-failure --state open --json number,title,url,body`;
      (b) for each failed run URL/id reported in the issue body and comments
          (`gh -R <owner/repo> issue view <n> --comments`), diagnoses via
          `gh -R <owner/repo> run view <run-id> --log-failed`;
      (c) fixes what is fixable within triage scope (same minimal-fix bar as step 2e) or escalates
          it into the feature scope with a log entry;
      (d) on completion: if all reported failures are resolved, write a summary to a
          `$RUN_TMPDIR` file via the Write tool and close with
          `gh -R <owner/repo> issue close <n> --comment-file <file>`; otherwise leave the issue
          open and post a status comment (`gh -R <owner/repo> issue comment <n> --body-file <file>`)
          describing what remains and why;
      (e) explicit no-issue path: empty list → append "no open dep-update-failure issues" to
          `.workflow/log.md` (Edit tool) and continue.
- [x] 003: `triage-dep-prs.md` — add flake.lock handoff consumption (adjacent to the section from
      task 002, as its own subsection). Instructions to add:
      (a) detect the handoff: check for branch `automated/update-flake-lock` ahead of main
          (`git -C <worktree> fetch origin` then
          `git -C <worktree> rev-list --count origin/main..origin/automated/update-flake-lock`;
          treat a missing remote branch as "no handoff") and/or an open issue labeled
          `flake-lock-update` (`gh -R <owner/repo> issue list --label flake-lock-update --state open --json number,title,url`);
      (b) if the branch exists ahead of main: open a PR from it with the user's plain `gh`
          credentials — NOT the bot wrapper — so CI triggers normally: write the body via the
          Write tool to `$RUN_TMPDIR/flake-pr-body.md`, then
          `gh -R <owner/repo> pr create --head automated/update-flake-lock --title "chore: update flake.lock" --body-file $RUN_TMPDIR/flake-pr-body.md`;
      (c) then treat that PR as a regular dep PR: run it through the existing Step 2 state machine
          (verify, lint/test, code-owner gate, CI, squash-merge);
      (d) after the PR merges, close the `flake-lock-update` handoff issue with a summary comment
          (Write tool file + `gh -R <owner/repo> issue close <n> --comment-file <file>`);
      (e) no-handoff path: neither branch-ahead nor open issue → log and continue.
- [x] 004: Check `.workflow/README.md` for contradictions with the new triage behavior.
      Pre-inspection result: it does not document the triage step at all (no mentions of triage,
      dep-update, or flake), so the expected outcome is NO change — re-verify with Grep and only
      edit if a contradicting description is actually found.
- [x] 005: Surgical-diff and command-shape audit. Run
      `git -C /Users/Private/Documents/Code/ProjectHana-worktrees/dep-update-failure-issues diff`
      and confirm: (a) the diff touches only the newly inserted step/sections in the two agent
      files (no rewording/renumbering of unrelated sections); (b) every command example added by
      tasks 001–003 is allowlist-shaped: `gh -R` / `git -C`, `--body-file`/`--comment-file`/`-F`
      with Write-tool-authored files, no `cd <path> && …`, no heredocs, no `$( … )` text payloads,
      no `for`/`while`/`seq` poll loops.
- [x] 006: Run `just -f /Users/Private/Documents/Code/ProjectHana-worktrees/dep-update-failure-issues/justfile lint`
      and fix any findings.
