# Before/after pass over prompt_required.txt

Each previously-prompted bucket is now covered by an applied command-shape convention and/or a
prepared allowlist entry (allowlist entries pending user application — see story 001).

| Prompted bucket (before) | Remedy | Status |
|---|---|---|
| `just … 2>&1 \| tail -30`, `… \| grep \| head`, `… \| wc` | allowlist `tail/head/wc/sort/cut/comm/uniq/nl/column/jq` | allowlist (story 001, pending apply) |
| `cd <worktree> && git/just …` | CLAUDE.md no-cd rule → `git -C`/`just -f`/`gh -R`; worktree-git wildcards | shape **applied** (002/003) + allowlist (001) |
| `git commit -m "$(cat <<'EOF')"` / `commit -F - <<EOF` | CLAUDE.md → write file + `git commit -F`; implement-story/create-pr edits | shape **applied** (002/003); `git commit *` already allowed |
| `cat >> log.md <<'EOF'` | CLAUDE.md → Edit/Write tool (no Bash) | shape **applied** (002) |
| `for i in $(seq …); do gh pr checks …; done` | CLAUDE.md → `gh pr checks --watch`; wait-for-ci edit; `sleep` allow | shape **applied** (002/003); `gh pr checks *` already allowed |
| inline `python3 -c …`, `grep -rn …` one-offs | CLAUDE.md → committed scripts / Read·Grep·Edit tools; `grep -r` allow | shape **applied** (002) |

## Hooks still fire
`permissions-<date>.jsonl` (PreToolUse capture) and `hooks-<date>.jsonl` (PostToolUse telemetry) both
grew during this run; `agent-log.sh` telemetry recorded every phase. No hook logic changed.

## Honest status
- **Behavioral remedies (stories 002 + 003): applied & committed.** These are the agent-side levers and
  cover every bucket.
- **Allowlist remedies (story 001): prepared, not applied** — the Auto-mode classifier blocks an agent
  from editing `.claude/settings.json` (self-granting permission). The user applies these (the exact
  entries are in `stories/001-allowlist-readonly-filters/proposed-settings-allow.json`).

`just lint` passes (Swift/Python/Shell/Nix/YAML).
