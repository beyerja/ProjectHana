# ProjectHana — agent operating conventions

These conventions apply to the main session **and** every workflow sub-agent in `.claude/agents/`.

## Prefer dedicated read-only tools over Bash for file inspection

Use the **Read**, **Grep**, and **Glob** tools — never shell `cat`, `head`, `tail`, `ls`, `find`,
or `grep` — to read files, search file contents, or list directories.

The dedicated tools never trigger a permission prompt, whereas the equivalent Bash commands cannot be
safely allowlisted (a wildcard like `Bash(cat *)` would also match `cat x; rm -rf y`, so they stay
prompted). Reaching for Read/Grep/Glob keeps the workflow flowing without the user having to approve
one-off inspection commands.

Reserve **Bash** for commands that have side effects or for tooling with no dedicated tool —
`git`, `gh`, `just`, `xcodebuild`, `direnv`, etc.

## Emit allowlistable command shapes

When you *do* reach for Bash, write the command in a shape the allowlist can match, so it runs without
a per-call approval prompt. Un-allowlistable shapes (a wildcard can't safely cover them) get prompted
**every single time** — they were the bulk of the manual approvals in workflow telemetry. Four rules:

- **No `cd <path> && …`.** A `cd /abs/path && <cmd>` compound can't be allowlisted and is prompted
  every run. Run side-effecting tools *at a path* instead: `git -C <dir> …`, `just -f <dir>/justfile …`
  (the recipes are worktree-aware), `gh -R <owner/repo> …`. The worktrees parent is pre-authorized, so
  you can operate inside `../ProjectHana-worktrees/<slug>` directly. Reserve `cd` for the rare tool with
  no path flag — and then run it as its own call, never chained with `&&`.

- **No heredocs or `$(…)` for text payloads.** Command substitution and heredocs are always prompted.
  - Commit messages: write the message to a file with the **Write** tool, then
    `git commit -F <file>` (or `git -C <dir> commit -F <file>`). Never `git commit -m "$(cat <<'EOF')"`
    or `git commit -F - <<'EOF'`.
  - PR bodies: write the body to a file and `gh pr create --body-file <file>` (not `--body "$(…)"`).
  - `.workflow/log.md` and story logs: append with the **Edit**/**Write** tool, never
    `cat >> log.md <<'EOF'`.

- **No `for`/`while`/`seq` poll loops.** To wait on CI use `gh pr checks <n> --watch --fail-fast` — it
  blocks until every check finishes. If the checks haven't registered yet, do a single `sleep <n>` then
  one `--watch`; do not hand-roll a polling loop (loops are always prompted).

- **Prefer one committed script over many inline one-offs.** Do repeated analysis or transforms through
  a committed `scripts/*.py` invoked by `just` (e.g. `just telemetry`), or the Read/Grep/Edit tools —
  not a series of `python3 -c "…"` / `grep -rn` invocations, which are prompted individually.

Note: editing the permission allowlist (`.claude/settings.json`) itself is intentionally **not**
something an agent can do under "Auto" permission mode — self-granting permission is blocked by design.
Allowlist changes are a human action; these command-shape rules are how an agent reduces prompts on its
own side.
