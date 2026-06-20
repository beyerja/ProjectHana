# Feature: Reduce permission prompts in the agentic workflow

## Goal

Cut the number of manual permission approvals required during a feature workflow run
(esp. under "Auto" permission mode) by (a) making the agents emit command shapes that are
*allowlistable* and (b) widening the committed allowlist with genuinely **safe, read-only**
entries. No change may broaden approval to a destructive command, and telemetry / permission-capture
hooks must keep working.

## Root-cause analysis (from the last 3 runs in prompt_required.txt)

Every prompted command falls into one of these buckets:

1. **Pipe to a read-only filter** — `just … 2>&1 | tail -30`, `… | grep -E … | tail`, `… | head`,
   `… | wc -l`. The leading tool is allowlisted but `tail`/`head`/`wc`/`sort`/`comm`/`cut` are not,
   so the pipe segment forces a prompt. *Largest single bucket.*
2. **`cd <abs-path> && <cmd>` compound** — the `cd` prefix makes the whole line un-allowlistable.
   The orchestrator already forbids this (use `git -C` / `just -f` / `gh -R`), but the rule never
   propagated to the sub-agents that actually run the commands (implement-story, create-pr, etc.).
3. **Heredoc command-substitution commits** — `git commit -m "$(cat <<'EOF' … EOF)"` and
   `git commit -F - <<'EOF'`. Command substitution / heredocs are always prompted.
4. **Heredoc log appends** — `cat >> .workflow/log.md <<'EOF' … EOF`.
5. **`for`/`while` CI-poll loops** — hand-rolled `for i in $(seq …); do gh pr checks …; done`. Loops
   are always prompted; `gh pr checks <n> --watch` (already allowlisted) does the same thing.
6. **Ad-hoc inline `python3 -c …` / `python3 - <<'PY'`** for telemetry analysis and bulk L10n edits,
   plus standalone `grep -rn`/`sed -n` that should be the Read/Grep tools.

## Acceptance Criteria

- [ ] **Allowlist — safe read-only filters.** `.claude/settings.json` allows the side-effect-free
      output filters that appear in pipes: `tail`, `head`, `wc`, `sort`, `cut`, `comm`, `uniq`, `nl`,
      `column`, `jq`. (No `echo`-with-redirect, no `rm`, no write-capable command.)
- [ ] **Allowlist — generalized worktree git.** Per-worktree read-only/standard git verbs are allowed
      under the stable parent via a wildcard path (`git -C …/ProjectHana-worktrees/* status|add|commit
      -F|push|log|diff|checkout|merge|fetch|branch|check-ignore|rev-parse|ls-files …`) so a *new*
      feature slug never re-prompts the same verbs. Destructive forms stay out.
- [ ] **No `cd`-compound in any agent.** Every `.claude/agents/*.md` instructs sub-agents to run
      side-effecting tools at a path (`git -C`, `just -f`, `gh -R`) and never `cd <path> && …`.
- [ ] **Commits without heredocs.** Agents write the commit message to a file with the Write tool and
      run `git commit -F <file>` (or `git -C <path> commit -F <file>`); `$(cat <<EOF)` /
      `commit -F - <<EOF` patterns are removed from agent guidance.
- [ ] **Log appends without heredocs.** Agents append to `.workflow/log.md` with the Edit/Write tool
      (or a dedicated allowlisted helper), not `cat >> … <<EOF`.
- [ ] **CI polling via `--watch`.** wait-for-ci / orchestrator use `gh pr checks <n> --watch
      --fail-fast` instead of `for`/`while` poll loops.
- [ ] **Ad-hoc analysis uses tools/scripts.** Agent guidance steers telemetry/codebase inspection to
      the Read/Grep/Glob tools and committed scripts (`just telemetry`, `scripts/*.py`) rather than
      inline `python3 -c` / `grep -rn` one-offs.
- [ ] A before/after pass over the prompt_required.txt commands shows each previously-prompted line is
      now either allowlisted or expressible as an allowlistable shape.
- [ ] `just lint` (sh/yaml/etc.) passes; the permission-capture and telemetry hooks still fire.

## Constraints

- **In-place meta run** (no worktree): edits land in the primary checkout because they modify the
  workflow tooling (`.claude/agents/`, `.claude/settings.json`).
- Allowlist additions must be **provably safe / read-only**. When in doubt, leave it to the LLM
  qualifier rather than allowlist it.
- Keep `.claude/settings.json` (committed, shared) for general rules; do not dump machine-specific
  one-offs there.
- Don't weaken the security posture: no secret-exfil-capable or destructive command becomes
  auto-approved.

## Out of Scope

- Changing the permission *mode* itself or Claude Code settings outside this repo.
- Reworking the telemetry schema or the hook scripts' logic.
- App/source (`Hanahuac/`) changes — this feature touches only workflow tooling.
