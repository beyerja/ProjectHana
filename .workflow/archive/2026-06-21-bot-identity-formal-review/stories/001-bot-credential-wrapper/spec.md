# 001 — Bot credential wrapper + secret-scanning pre-commit hook

## Title
Committed Keychain-backed `gh-review-bot.sh` wrapper and a secret-scanning pre-commit hook

## Goal
Provide the single sanctioned path for an agent to authenticate as the `Hanahuac-Bot`
identity without ever reading, printing, or committing the token, plus defense-in-depth that
blocks any commit containing a token-like string. This is the foundation every later story
builds on (story 002 calls this wrapper). Everything here is testable WITHOUT the real token
present.

## Scope
- `scripts/gh-review-bot.sh` (committed, executable).
- A secret-scanning pre-commit hook (committed, e.g. `scripts/hooks/pre-commit-secret-scan.sh`)
  plus the wiring/install step (e.g. a `just` recipe or `scripts/install-hooks.sh`) that
  registers it as the repo's `pre-commit` hook.

## Acceptance Criteria
- [ ] `scripts/gh-review-bot.sh` exists, is committed, and is executable (`chmod +x`).
- [ ] The wrapper reads the token from the macOS Keychain service `hana-review-bot`
      (`security find-generic-password -s hana-review-bot -w`) into a subprocess `GH_TOKEN`
      environment variable and `exec`s the underlying command (`gh …` / `curl …`) passed as
      its arguments.
- [ ] The wrapper never prints the token: it runs with `set +x` (or never enables `-x`), never
      `echo`s `$GH_TOKEN`, and never writes the token to any file. A grep of the script shows
      no `echo`/`printf`/redirection of the token value.
- [ ] When the Keychain item is ABSENT, the wrapper exits non-zero with a clear, actionable
      message (naming the service `hana-review-bot` and pointing at the setup docs) and does
      NOT run the underlying command. This path is verifiable on a machine without the token.
- [ ] The wrapper passes its arguments through to the target command unchanged (e.g.
      `scripts/gh-review-bot.sh gh api user` would exec `gh api user` with `GH_TOKEN` set);
      verified by a dry-run/stub test that asserts arg-passthrough without needing the token.
- [ ] A pre-commit hook is committed that scans staged content and rejects the commit
      (non-zero exit, clear message) when it finds a `github_pat_…` or `ghp_…` pattern.
- [ ] The hook's rejection is demonstrated on a PLANTED fake token string (e.g.
      `ghp_FAKE0000000000000000000000000000000000`) and the hook does NOT trigger on ordinary
      content.
- [ ] An install/wiring step is committed and documented so the hook can be activated on a
      fresh clone (hooks are not version-controlled by default).
- [ ] No real token is required for any of the above tests to pass.

## Notes
- Follow CLAUDE.md command-shape rules; the wrapper itself must be safe to `git add`.
- Keep the wrapper minimal: token read -> export to subprocess env -> `exec "$@"`.
