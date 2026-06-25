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

   - **Pull requests: Read & Write** — required to submit a formal `--approve` review.
   - **Contents: Read-only** and **Metadata: Read-only** — the minimal repo permission needed to read
     the PR / resolve the repo. (Metadata is mandatory and auto-selected.)

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

Then run the [AC-1 verification procedure](#ac-1-verification-procedure-run-once-the-app-is-provisioned)
below to empirically confirm the App can clear the 1-approval gate **before** any live ruleset change.

## Using the wrapper

Prefix any bot GitHub command with the wrapper. It mints a short-lived installation token from the
Keychain-stored App credentials and injects it as `GH_TOKEN` into the child process only:

```sh
scripts/gh-review-bot.sh gh api user
scripts/gh-review-bot.sh gh -R beyerja/ProjectHana pr review 123 --approve --body "LGTM"
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
read-only call (the wrapper now mints tokens from the new key):

```sh
scripts/gh-review-bot.sh gh api user
```

## AC-1 verification procedure (run once the App is provisioned)

> **HANDOFF — human-run, empirical.** This procedure is performed by a maintainer once the App above is
> provisioned. It is the **linchpin** check (feature AC-1): it proves a GitHub App's `--approve` review
> satisfies `required_approving_review_count: 1` on `beyerja/ProjectHana`, and it captures the App's
> **actual** bot login (the string AC-3 and AC-5 consume). **No agent executes this** — until a human
> runs it, AC-1 is BLOCKED-pending-human and the App's bot login is UNKNOWN. **Do NOT flip ruleset
> `17373423` or delete `.github/CODEOWNERS` until this check is empirically green.** No secret (private
> key, App ID, installation ID, or installation token) is ever echoed, redirected, written, or
> committed during this procedure.

Run, in order:

1. **Open a throwaway PR against `main`.** Create a scratch branch off `main` with a trivial,
   easily-reverted change (e.g. a whitespace-only edit to a scratch file), push it, and open a PR
   targeting `main`. This is the safe surface to test the gate on — do not test on a real story PR.

2. **Have the App submit a `--approve` review on that PR.** Two options:

   - **Preferred (once AC-2 lands):** use the wrapper, which mints the short-lived installation token
     internally and never echoes it:

     ```sh
     scripts/gh-review-bot.sh gh -R beyerja/ProjectHana pr review <pr-number> --approve --body "AC-1 verification"
     ```

   - **For the verification itself, before AC-2:** mint an installation token manually, keeping the
     secret out of history and output. Build a short-lived RS256 JWT from the App private key and App
     ID, exchange it at `POST /app/installations/<installation_id>/access_tokens`, and use the
     returned token to submit the review. Keep the private key and token in environment/process state
     only — **never** echo them, write them to a file, or enable shell xtrace. (The committed wrapper
     in AC-2 codifies exactly this mint-and-inject flow; prefer it as soon as it exists.)

3. **Confirm the review satisfies the gate.** Verify the App's review registers as an `APPROVED`
   review state on the PR and that the PR's mergeability reflects a satisfied
   `required_approving_review_count: 1` against ruleset `17373423`. Read-only checks only — do **not**
   modify the ruleset:

   ```sh
   gh -R beyerja/ProjectHana pr view <pr-number> --json reviews,reviewDecision
   gh api repos/beyerja/ProjectHana/rulesets/17373423   # read-only, to confirm the live rule shape
   ```

   > Note: at the time of this writing the live `main` ruleset still has
   > `require_code_owner_review: true` / `required_approving_review_count: 0`. The atomic cutover to
   > `required_approving_review_count: 1` (code-owner off) is the **final** feature story (AC-5) and is
   > gated on this AC-1 check passing. The empirical confirmation here can be done by inspecting the
   > review state; do not pre-flip the ruleset to "make it pass."

4. **Capture and record the App's ACTUAL bot login.** Read it back from the submitted review — do not
   assume it:

   ```sh
   gh -R beyerja/ProjectHana pr view <pr-number> --json reviews \
     --jq '.reviews[] | {login: .author.login, state: .state}'
   ```

   The expected form is `hanahuac-bot[bot]`, but the suffix derives from the App's name and **must be
   confirmed (or corrected) empirically here**. Record the exact string — it is the value AC-3's
   reviews read-back and `resolveReviewThread` author filter assert against, and the gate AC-5 relies
   on. This login string is the confirmation artifact this story OWES downstream.

5. **Clean up the throwaway PR/branch.** Close the PR and delete the scratch branch:

   ```sh
   gh -R beyerja/ProjectHana pr close <pr-number> --delete-branch
   ```

6. **Record the outcome.** Note pass/fail and the captured login string in the story log /
   handoff record. Until this is recorded as **green** with a confirmed login, the live cutover
   (AC-5: flip ruleset `17373423`, delete `.github/CODEOWNERS`) stays blocked.

**Constraints restated (do not violate):** no secret is ever read, echoed, or persisted by an agent;
the App's bot login is confirmed empirically, never fabricated; and **the ruleset is NOT flipped and
`.github/CODEOWNERS` is NOT deleted until AC-1 is empirically green.**
