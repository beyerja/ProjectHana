# Bot credentials — Hanahuac-Bot identity

The `Hanahuac-Bot` identity lets an agent act on GitHub (review PRs, comment) as a distinct,
least-privilege account rather than as a human maintainer. Its token lives **only** in the macOS
Keychain and is never read, printed, or committed.

**Agents NEVER see the token.** It is read **only** by the wrapper `scripts/gh-review-bot.sh` (story
001), which looks the token up in the Keychain (service `hana-review-bot`), injects it into a child
process's environment, and execs the underlying `gh`/`curl` command. The wrapper never prints, logs,
or writes the token (xtrace stays off), and agents only ever invoke the wrapper — they do not read the
Keychain or set `GH_TOKEN` themselves. The three prerequisites below are likewise **human-performed
out-of-band**: no agent mints the PAT, grants collaborator access, or stores the secret.

## Human prerequisites (one-time, three steps)

These three steps require a human and are intentionally **not** automatable by an agent — an agent
**never sees the token**. All three are performed out-of-band by a maintainer:

1. **Mint the bot's classic PAT.** Sign in as the `Hanahuac-Bot` GitHub account and create a
   **classic** personal access token (Settings → Developer settings → **Tokens (classic)**) with the
   single scope:

   - **`public_repo`** — write access to this *public* repo's PRs, reviews, and comments. (Use the
     broader **`repo`** scope only if `ProjectHana` is ever made private.)

   Copy the token once — GitHub shows it only at creation time.

   > **Why classic, not fine-grained.** `ProjectHana` is a *public* repo owned by the personal
   > account `beyerja`, and `Hanahuac-Bot` is an outside collaborator. A fine-grained PAT from the
   > bot authenticates and can *read*, but every write (e.g. submitting a formal PR review) returns
   > `403 Resource not accessible by personal access token` even with Pull requests: Read/Write set —
   > fine-grained PATs do not grant write to a *different personal account's* repo via outside
   > collaboration. A classic PAT does. (If the repo ever moves into a GitHub organization, a
   > fine-grained PAT or a GitHub App becomes the better least-privilege option.)

2. **Add `Hanahuac-Bot` as a repository collaborator with Write access, and accept the invite.** As a
   repo admin, invite the `Hanahuac-Bot` account as a collaborator with the **Write** role (Settings →
   Collaborators). Then sign in as `Hanahuac-Bot` and **accept the invitation**. Without this, the bot
   cannot be a code owner or submit a formal review state on the repo's PRs.

3. **Store the token in the macOS Keychain** under service `hana-review-bot`. Run the command below
   and paste the token at the (hidden) `-w` prompt — do **not** pass the token on the command line
   (it would land in your shell history):

   ```sh
   security add-generic-password -a "$USER" -s hana-review-bot -U -w
   ```

   - `-s hana-review-bot` is the Keychain **service** name the wrapper looks up. It must match exactly.
   - `-a "$USER"` is the account label (your macOS login name; used for your own reference).
   - `-U` upserts: it updates the item in place if it already exists, so the same command also serves
     rotation (below).
   - `-w` with no value makes `security` prompt for the secret interactively, keeping it out of history.

After the three prerequisites are done, **activate the secret-scanning pre-commit hook** in your clone
(git hooks are not version-controlled):

```sh
just install-hooks
```

## Using the wrapper

Prefix any bot GitHub command with the wrapper. It injects `GH_TOKEN` into the child process only:

```sh
scripts/gh-review-bot.sh gh api user
scripts/gh-review-bot.sh gh -R beyerja/ProjectHana pr review 123 --approve --body "LGTM"
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

Rotate the token periodically and immediately if you suspect exposure. **No repo, working-tree, or
code change is required** — the wrapper always reads the current Keychain value, so rotation is purely
a Keychain + GitHub operation:

1. **Mint a new** classic PAT as `Hanahuac-Bot` with the **same scope** as the original
   (`public_repo`, or `repo` if the repo is ever private). Copy it once.
2. **Update the Keychain item in place** with the `-U` upsert form (identical to the store command —
   `-U` updates the existing item):

   ```sh
   security add-generic-password -a "$USER" -s hana-review-bot -U -w
   ```

   Paste the new token at the hidden prompt.
3. **Revoke the old PAT** on GitHub so only the new token is valid.

Then verify with a read-only call (the wrapper now reads the new token from the Keychain):

```sh
scripts/gh-review-bot.sh gh api user
```
