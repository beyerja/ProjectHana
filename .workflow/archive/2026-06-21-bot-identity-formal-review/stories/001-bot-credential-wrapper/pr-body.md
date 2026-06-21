## Goal

Provide the single sanctioned path for an agent to authenticate as the `Hanahuac-Bot` identity without ever reading, printing, or committing the token, plus defense-in-depth that blocks any commit containing a token-like string. This is the foundation every later story builds on (story 002 calls this wrapper). Everything here is testable WITHOUT the real token present.

## Summary of changes

- **`scripts/gh-review-bot.sh`** — committed, executable Keychain-backed wrapper. Reads the bot token from the macOS Keychain service `hana-review-bot` into a subprocess `GH_TOKEN` and `exec`s the underlying command (`gh …` / `curl …`) passed as its arguments. Never echoes/printfs/redirects the token, never enables `-x`, never writes it to a file. Fails closed (non-zero, actionable message naming the service and pointing at the setup docs) when the Keychain item is absent, without running the underlying command.
- **`scripts/hooks/pre-commit-secret-scan.sh`** — committed secret-scanning pre-commit hook. Scans staged content and rejects the commit (non-zero, clear message) on a `github_pat_…` or `ghp_…` pattern; does not trigger on ordinary content.
- **Install wiring** — `scripts/install-hooks.sh` plus a `just install-hooks` recipe register the hook as the repo's `pre-commit` hook on a fresh clone (hooks are not version-controlled by default).
- **Token-free test harnesses** — `just test-bot-scripts` exercises arg-passthrough (dry-run/stub), the absent-Keychain fail-closed path, and the hook's rejection of a planted fake token (`ghp_FAKE…`) plus its no-op on ordinary content. No real token required.
- **`docs/bot-credentials.md`** — documents setup, the wrapper, the hook, and install steps.

## Test plan

- [x] `scripts/gh-review-bot.sh` exists, is committed, executable.
- [x] Wrapper reads token from Keychain service `hana-review-bot` into subprocess `GH_TOKEN` and `exec`s the passed command.
- [x] Wrapper never prints/redirects the token (grep-verified; no `-x`).
- [x] Absent-Keychain path exits non-zero with an actionable message and does NOT run the command.
- [x] Arg-passthrough verified by dry-run/stub test without the token.
- [x] Pre-commit hook rejects `github_pat_…` / `ghp_…` patterns in staged content.
- [x] Hook rejection demonstrated on a planted fake token; no false trigger on ordinary content.
- [x] Install/wiring step committed and documented (`just install-hooks`).
- [x] All checks green; all tests pass without the real token.
