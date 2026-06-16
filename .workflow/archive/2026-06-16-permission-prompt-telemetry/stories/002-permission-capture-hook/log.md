# Story 002 — log

- break-tasks: focused single-script story; tasks tracked via task list (implement script, register hook, test+lint, lifecycle).
- implement: added `scripts/permission-capture-hook.sh` (sh + python3, fail-open). Registered `PreToolUse` matcher `Bash` in `.claude/settings.json`; PostToolUse untouched. Added single allow entry `Bash(bash scripts/permission-capture-hook.sh*)`.
  - Payload passed to embedded python via env var (`HOOK_PAYLOAD`) because the heredoc occupies python's stdin.
  - Allowlist = union of `permissions.allow` Bash(...) patterns from settings.json + settings.local.json; trailing/interior `*` handled (prefix + fnmatch).
- test: all acceptance criteria verified locally (match/no-match against both files, fail-open empty+malformed, non-Bash tool-name-only record, interior wildcard, gitignore). `just lint-sh` (shellcheck) passes.
