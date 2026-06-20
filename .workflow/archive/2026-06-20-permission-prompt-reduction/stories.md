# Stories: Reduce permission prompts

In-place meta run (no worktree). Single feature branch `feat/permission-prompt-reduction`,
one PR, one commit per story.

- [ ] **001-allowlist-readonly-filters** — Widen `.claude/settings.json` with provably safe,
      read-only entries: output filters (`tail/head/wc/sort/cut/comm/uniq/nl/column/jq`),
      `sleep`, `grep -r`, and *generalized* worktree-git wildcards so a new feature slug never
      re-prompts the same git verbs. (AC: allowlist-readonly-filters, allowlist-worktree-git)

- [ ] **002-shared-command-shape-conventions** — Add an "Emit allowlistable command shapes"
      section to `CLAUDE.md` (which already governs the main session + every sub-agent): no
      `cd <path> && …` (use `-C`/`-f`/`-R`); no heredocs for commit messages, PR bodies, or log
      appends (write a file + `git commit -F` / `gh pr create --body-file`, or the Edit/Write tool);
      no `for`/`while`/`seq` CI-poll loops (use `gh pr checks <n> --watch --fail-fast`); prefer one
      committed script over many inline `python3 -c`. (AC: no-cd-compound, heredoc-free-commits,
      heredoc-free-logs, ci-watch, adhoc-analysis)

- [ ] **003-apply-conventions-to-agents** — Fix the concrete offenders so the agent files match the
      new convention: `create-pr.md` ("Always pass body via HEREDOC" → `--body-file`), `merge-pr.md`
      & `implement-story.md` (commit via `-F <file>`), `wait-for-ci.md`/`feature_orchestrator.md`
      (no registration poll loops; a single `--watch`, brief `sleep` if needed), and align the
      existing cd-avoidance notes in `feature_orchestrator.md` / `evaluate-workflow.md` to reference
      the shared convention. (AC: no-cd-compound, heredoc-free-commits, ci-watch)

Feature-level verify covers the before/after pass over prompt_required.txt (AC: before-after-pass)
and `just lint` + hooks-still-fire (AC: lint-and-hooks).
