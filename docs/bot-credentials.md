# Bot credentials — Hanahuac-Bot identity

The `Hanahuac-Bot` identity lets an agent act on GitHub (review PRs, comment) as a distinct,
least-privilege account rather than as a human maintainer. Its token lives **only** in the macOS
Keychain and is never read, printed, or committed. The sanctioned way to use it is the wrapper
`scripts/gh-review-bot.sh`, which reads the token from the Keychain into a subprocess environment
variable and execs the underlying `gh`/`curl` command.

## Human prerequisites (one-time, three steps)

These three steps require a human and are intentionally **not** automatable by an agent:

1. **Create the bot's fine-grained PAT.** Sign in as the `Hanahuac-Bot` GitHub account and create a
   fine-grained personal access token scoped to this repository with the least privilege the bot
   needs (e.g. read/write on Pull requests and Contents). Copy the token once — GitHub shows it only
   at creation time.

2. **Store the token in the macOS Keychain** under service `hana-review-bot`. Run the command below
   and paste the token at the (hidden) `-w` prompt — do **not** pass the token on the command line
   (it would land in your shell history):

   ```sh
   security add-generic-password -s hana-review-bot -a hanahuac-bot -w
   ```

   - `-s hana-review-bot` is the Keychain **service** name the wrapper looks up. It must match exactly.
   - `-a hanahuac-bot` is an account label (any value; used for your own reference).
   - `-w` with no value makes `security` prompt for the secret interactively, keeping it out of history.

3. **Activate the secret-scanning pre-commit hook** in your clone (git hooks are not version-controlled):

   ```sh
   just install-hooks
   ```

## Using the wrapper

Prefix any bot GitHub command with the wrapper. It injects `GH_TOKEN` into the child process only:

```sh
scripts/gh-review-bot.sh gh api user
scripts/gh-review-bot.sh gh pr review 123 --approve --body "LGTM"
```

Behavior:

- Reads the token from Keychain service `hana-review-bot` and execs your command with `GH_TOKEN` set.
- **Never** prints, logs, or writes the token (xtrace is never enabled).
- If the Keychain item is **absent**, it exits non-zero with an actionable message and does **not**
  run the underlying command — so it is safe on a machine that has never had the token installed.
- Passes all arguments through unchanged.

## Secret-scanning pre-commit hook

`scripts/hooks/pre-commit-secret-scan.sh` (installed via `just install-hooks`) scans **staged** content
on every commit and **rejects** the commit if it finds a GitHub token-shaped string
(`ghp_<36 chars>` or `github_pat_<…>`). This is defense-in-depth against accidentally `git add`-ing a
real token. Ordinary content commits normally. Test fixtures that need a token-shaped string use the
clearly-fake `ghp_FAKE…` sentinel, which the hook allowlists.

Run the token-free tests for both the wrapper and the hook at any time:

```sh
just test-bot-scripts
```

## Token rotation

Rotate the token periodically and immediately if you suspect exposure:

1. On GitHub, as `Hanahuac-Bot`, **generate a new** fine-grained PAT (or regenerate the existing one)
   with the same scopes. **Revoke** the old token.
2. Update the Keychain entry in place (the `-U` flag updates an existing item):

   ```sh
   security add-generic-password -U -s hana-review-bot -a hanahuac-bot -w
   ```

   Paste the new token at the prompt. No code or config changes are needed — the wrapper always reads
   the current Keychain value.
3. Verify with a read-only call:

   ```sh
   scripts/gh-review-bot.sh gh api user
   ```
