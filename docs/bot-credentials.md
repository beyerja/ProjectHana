# Bot credentials — Hanahuac-Bot identity (GitHub App)

The `Hanahuac-Bot` identity lets an agent act on GitHub (review PRs, comment) as a distinct,
least-privilege actor rather than as a human maintainer. The identity is a **GitHub App**: at runtime
the wrapper mints a **short-lived installation token** (auto-expiring, ~1h) from the App's credentials,
so the only long-lived secret at rest is the App **private key**.

All secrets live **only** in the macOS Keychain (service `hana-review-bot`) and are never read, printed,
or committed. They are read **only** by the wrapper `scripts/gh-review-bot.sh`, which looks them up in
the Keychain, mints the installation token, injects it into a child process's environment, and execs the
underlying `gh`/`curl` command. The wrapper never prints, logs, or writes any secret (xtrace stays off),
and agents only ever invoke the wrapper — they do not read the Keychain or set `GH_TOKEN` themselves.

**Agents NEVER see the secrets.** The provisioning steps below are likewise **human-performed
out-of-band**: no agent creates the App, generates the private key, installs the App, or stores anything
in the Keychain.

## Contents

- [GitHub App provisioning (human prerequisites)](#github-app-provisioning-human-prerequisites)
- [Using the wrapper](#using-the-wrapper)
- [Secret-scanning pre-commit hook](#secret-scanning-pre-commit-hook)
- [Private key rotation](#private-key-rotation)
- [AC-1 verification procedure](#ac-1-verification-procedure-run-once-the-app-is-provisioned)

## GitHub App provisioning (human prerequisites)

> **HANDOFF — human-performed, out-of-band.** Every step below is done by a maintainer at the
> keyboard; **no agent performs them and no agent ever sees the resulting secrets** (App private key,
> App ID, installation ID, or any minted installation token).

Provision the App once, in order:

1. **Create a GitHub App owned by the personal account `beyerja`.**
   GitHub → Settings → Developer settings → **GitHub Apps** → **New GitHub App**. Owner = `beyerja`
   (a personal account is fine; no organization required). A descriptive name such as `Hanahuac Bot`
   is recommended — GitHub derives the bot login from it (expected form `hanahuac-bot[bot]`; the
   actual login is confirmed empirically in the [AC-1 procedure](#ac-1-verification-procedure-run-once-the-app-is-provisioned)).
   A homepage URL is required by the form but irrelevant here; the repo URL works. The App does not
   need a webhook — uncheck **Active** under *Webhook*.

2. **Set the minimal permissions.** Under *Repository permissions*:

   - **Checks: Read & Write** — required to post the `code-owner-review` status check that gates merge.
     This is the mechanism the bot uses (a GitHub App's *review* carries `author_association: NONE` and
     does **not** count toward a required-review gate; a *status check* from the App is honored, and the
     required check is pinned to the App's id so no other account can satisfy it).
   - **Pull requests: Read & Write** — read the PR/diff and post review comments.
   - **Contents: Read-only** and **Metadata: Read-only** — minimal repo permission to read the PR /
     resolve the repo. (Metadata is mandatory and auto-selected.)

   Grant nothing else. No organization or account permissions are needed.

3. **Generate a private key (`.pem`).** On the App's settings page → *Private keys* → **Generate a
   private key**. The browser downloads a `<app-name>.YYYY-MM-DD.private-key.pem`. This file is the
   one long-lived secret at rest; keep it off any shared/synced location until it is in the Keychain
   (step 5), then delete the downloaded file.

4. **Install the App on `beyerja/ProjectHana`.** App settings → *Install App* → install on the
   `beyerja` account and scope it to **Only select repositories → `ProjectHana`**. After installing,
   note the **installation ID** — it is the numeric segment in the install settings URL
   (`https://github.com/settings/installations/<installation_id>`). You also need the **App ID**,
   shown at the top of the App's settings page (a separate number from the installation ID).

5. **Store the private key + App ID + installation ID in the macOS Keychain** under service
   `hana-review-bot`. The three items are distinguished by **account** (`-a`) — these exact account
   names are what the wrapper (`scripts/gh-review-bot.sh`) reads, so they must match verbatim:
   `private-key`, `app-id`, `installation-id`. Use the interactive hidden-prompt `-w` form so **no
   secret ever appears on the command line or in shell history** — run each command, then paste the
   value at the (hidden) prompt:

   ```sh
   # Private key — paste the full PEM (including the BEGIN/END lines) at the hidden prompt:
   security add-generic-password -s hana-review-bot -a private-key -U -w

   # App ID — paste the numeric App ID at the hidden prompt:
   security add-generic-password -s hana-review-bot -a app-id -U -w

   # Installation ID — paste the numeric installation ID at the hidden prompt:
   security add-generic-password -s hana-review-bot -a installation-id -U -w
   ```

   - `-s hana-review-bot` is the Keychain **service** the wrapper looks up — it must match exactly.
   - `-a private-key` / `-a app-id` / `-a installation-id` are the **account** names the wrapper reads
     (`security find-generic-password -s hana-review-bot -a <account>`); the three items coexist under
     the one service because their accounts differ. Use these strings verbatim.
   - `-U` upserts (updates in place if present), so the same commands also serve key rotation.
   - `-w` with no value makes `security` prompt for the secret **interactively**, keeping it out of
     shell history.

   After all three are stored, **delete the downloaded `.pem`** — the Keychain now holds the only copy
   you need.

After provisioning, **activate the secret-scanning pre-commit hook** in your clone (git hooks are not
version-controlled):

```sh
just install-hooks
```

Then run the [check-gate verification procedure](#ac-1-verification-procedure-run-once-the-app-is-provisioned)
below to empirically confirm the App can post the gating `code-owner-review` check.

## Using the wrapper

Prefix any bot GitHub command with the wrapper. It mints a short-lived installation token from the
Keychain-stored App credentials and injects it as `GH_TOKEN` into the child process only:

```sh
scripts/gh-review-bot.sh gh api repos/beyerja/ProjectHana --jq .full_name   # read-only sanity check
scripts/gh-review-bot.sh gh api -X POST repos/beyerja/ProjectHana/check-runs \
  -f name=code-owner-review -f head_sha=<sha> -f status=completed -f conclusion=success
```

Behavior:

- Reads the three App items (`-a private-key`, `-a app-id`, `-a installation-id`) from Keychain service
  `hana-review-bot`, builds an RS256-signed JWT from the private key + App ID, exchanges it for a
  **short-lived installation token**, and execs your command with `GH_TOKEN` set. It does **not** read
  a static `GH_TOKEN`/PAT.
- **Never** prints, logs, or writes any secret (the private key, JWT, or installation token); xtrace is
  never enabled.
- **Fails closed if ANY of the three Keychain items is absent/empty** — it exits non-zero with an
  actionable message and does **not** run the underlying command, so it is safe on a machine that has
  never had the credentials installed.
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

## Private key rotation

The App **private key** is the only long-lived secret to rotate; runtime installation tokens
self-expire (~1h), so there is no token to revoke. **No repo, working-tree, or code change is
required** — the wrapper always reads the current Keychain value, so rotation is purely a Keychain +
GitHub operation:

1. **Generate a new private key** on the App's settings page → *Private keys* → **Generate a private
   key**. A new `.pem` downloads.
2. **Update the Keychain item in place** with the `-U` upsert form (identical to the store command —
   `-U` updates the existing `-a private-key` item). Paste the new PEM at the hidden prompt:

   ```sh
   security add-generic-password -s hana-review-bot -a private-key -U -w
   ```

3. **Delete the old private key** on the App's settings page (and the freshly downloaded `.pem` on
   disk) so only the new key is valid.

The App ID and installation ID are stable and do not change on key rotation. Then verify with a
read-only call (the wrapper now mints tokens from the new key; an installation token cannot hit
`/user`, so read the repo instead):

```sh
scripts/gh-review-bot.sh gh api repos/beyerja/ProjectHana --jq .full_name
```

## How the merge gate works (GitHub App status check)

The bot does **not** *approve* PRs. A GitHub App's review carries `author_association: NONE` and is not
counted toward a required-review gate (verified empirically). Instead the App posts a **required status
check** named **`code-owner-review`**, and branch protection requires that check — **pinned to the App's
id** (`4144849`), so no other account can satisfy it. The `code-owner-review` agent forms an independent
verdict and posts the check `success` (clears the gate) or `failure` (blocks it). The wrapper mints the
short-lived installation token internally; no secret is ever echoed, written, or committed.

The gate spans **two layers** (both configured, recorded here for reference / disaster recovery):

- **Classic branch protection** on `main` (`PUT /repos/beyerja/ProjectHana/branches/main/protection`):
  required status checks are `gitleaks`, `Build & Test` (CI, app_id `15368`) **plus**
  `{context: "code-owner-review", app_id: 4144849}`; `required_pull_request_reviews` is `null` (no
  approving-review requirement — the App can't satisfy one); `enforce_admins` is `false` (the repo owner
  can bypass in an emergency).
- **Ruleset `17373423`**: `require_code_owner_review: false`; `.github/CODEOWNERS` removed (it only
  weaponized the now-disabled code-owner rule).

The App id used for pinning is whatever the App reports on a check it posts: read it from
`…/check-runs … .app.id` (it equals the App ID on the App's settings page).

### Verify the gate (read-only, once provisioned)

1. Have the App post a check on a throwaway PR's head SHA, then confirm the PR is unblocked:

   ```sh
   sha=$(gh -R beyerja/ProjectHana pr view <pr> --json headRefOid --jq .headRefOid)
   scripts/gh-review-bot.sh gh api -X POST repos/beyerja/ProjectHana/check-runs \
     -f name=code-owner-review -f head_sha="$sha" -f status=completed -f conclusion=success
   scripts/gh-review-bot.sh gh api repos/beyerja/ProjectHana/commits/$sha/check-runs \
     --jq '.check_runs[]|select(.name=="code-owner-review")|{conclusion, app_id:.app.id}'
   gh -R beyerja/ProjectHana pr view <pr> --json mergeStateStatus   # CLEAN when satisfied
   ```

2. Posting `conclusion=failure` instead must flip the PR to `BLOCKED` — that confirms the check truly
   gates the merge, not merely that a green check is allowed. Clean up the throwaway PR afterward.
