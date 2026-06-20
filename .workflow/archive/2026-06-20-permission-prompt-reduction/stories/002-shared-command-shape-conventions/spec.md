# Story 002 — Shared "emit allowlistable command shapes" conventions in CLAUDE.md

## Goal
Put the behavioral rules in the one place that governs the main session AND every sub-agent
(`CLAUDE.md`), so agents emit command shapes that allowlist cleanly instead of getting prompted.

## Changes
Add a new section to `CLAUDE.md` (alongside the existing Read/Grep/Glob preference) titled
"Emit allowlistable command shapes", covering:
- **No `cd <path> && …`.** Run side-effecting tools at a path: `git -C <dir>`, `just -f <dir>/justfile`,
  `gh -R <owner/repo>`. The worktrees parent is pre-authorized. Reserve `cd` for the rare tool with
  no path flag (and even then, run it as its own call, not a `&&` chain).
- **No heredocs / command substitution for text payloads.** For commit messages write the message to a
  file with the Write tool and `git commit -F <file>` (or `git -C <dir> commit -F <file>`); for PR
  bodies use `gh pr create --body-file <file>`; for `.workflow/log.md` and story logs use the
  Edit/Write tool — never `git commit -m "$(cat <<'EOF')"`, `commit -F - <<'EOF'`, or
  `cat >> log.md <<'EOF'`. (`$(…)` and heredocs are always prompted.)
- **No `for`/`while`/`seq` poll loops.** Wait on CI with `gh pr checks <n> --watch --fail-fast`
  (it blocks until checks finish). If checks haven't registered yet, a single `sleep <n>` then one
  `--watch` — not a hand-rolled loop.
- **Prefer one committed script over many inline one-offs.** Do repeated analysis/transforms via a
  committed `scripts/*.py` invoked through `just`, or the Read/Grep/Edit tools — not a series of
  `python3 -c "…"` / `grep -rn` invocations.

## Acceptance Criteria
- [ ] `CLAUDE.md` has the new section covering all four rules.
- [ ] The section is concise and consistent with the existing tone; it states the *why*
      (un-allowlistable shapes get prompted every time).
- [ ] `just lint` passes.
