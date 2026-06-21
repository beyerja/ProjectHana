## Tasks

Documentation-only story. Canonical-source decision (made here, applied below): **extend the
existing `docs/bot-credentials.md`** as the single canonical setup+rotation page rather than adding
a competing `docs/bot-review-setup.md` — this keeps the docs set coherent (one page, one set of
steps, no conflicting commands). All other docs cross-reference it. The spec's
`security add-generic-password -a "$USER" -s hana-review-bot -U -w` is the authoritative Keychain
form and must replace the current `-a hanahuac-bot` form everywhere.

- [x] 001: Reconcile the Keychain account flag across all docs to the spec-canonical form. In
      `docs/bot-credentials.md`, change the store command (currently
      `security add-generic-password -s hana-review-bot -a hanahuac-bot -w`) and the rotation
      command (currently `... -U -s hana-review-bot -a hanahuac-bot -w`) to use `-a "$USER"`, and
      update the inline explanation of the `-a` flag accordingly. Grep the whole repo for
      `-a hanahuac-bot` to confirm no other doc/file still uses the old account label; this is the
      single canonical form going forward.

- [x] 002: In `docs/bot-credentials.md`, document the **3 human prerequisites verbatim and
      step-by-step** so all three AC-1 items are present and exact: (a) mint a fine-grained PAT as
      the `Hanahuac-Bot` account scoped to **ONLY this repository**, with permissions **Pull
      requests: Read/Write, Contents: Read, Metadata: Read** (replace the current vaguer
      "read/write on Pull requests and Contents" wording with this exact permission set); (b) add
      `Hanahuac-Bot` as a **repo collaborator with Write access and accept the invite** (this step
      is currently missing from the page — add it); (c) store the token via
      `security add-generic-password -a "$USER" -s hana-review-bot -U -w`. State explicitly that all
      three are **human-performed out-of-band** and not automatable by an agent.

- [x] 003: In `docs/bot-credentials.md`, ensure the "agents NEVER see the token" guarantee is
      stated plainly (AC-2): the token lives only in the macOS Keychain and is read **only by
      `scripts/gh-review-bot.sh`** (story 001), which injects it into a child process and never
      prints/logs/writes it. Confirm the page does not contain any token value or secret — only the
      commands a human runs and the service name `hana-review-bot` (AC-5).

- [x] 004: In `docs/bot-credentials.md`, finalize the **token ROTATION procedure** (AC-3) as the
      three no-working-tree-change steps: (1) mint a new fine-grained PAT (same scopes); (2) update
      the Keychain item in place using the `-U` upsert form —
      `security add-generic-password -a "$USER" -s hana-review-bot -U -w` — paste the new token at
      the hidden prompt; (3) **revoke the old PAT** on GitHub. State that no repo/working-tree/code
      change is required because the wrapper always reads the current Keychain value. Keep the
      read-only verification call (`scripts/gh-review-bot.sh gh api user`).

- [x] 005: Expand the **"Obligatory review gate"** section of `.workflow/README.md` (do NOT
      duplicate the existing stub at lines ~52-67; build on it) to describe the new review mechanics
      for AC-4: (a) **bot-authenticated formal review submission** via `scripts/gh-review-bot.sh gh
      pr review` under the `Hanahuac-Bot` identity (why a separate account: GitHub blocks
      self-approval by the PR opener); (b) the **formal review states** `APPROVE` /
      `REQUEST_CHANGES` with the `COMMENT`-type fallback when the bot token is absent, noting these
      are **additive** and that the agent's `STATUS:` line remains the authoritative loop signal;
      (c) **thread resolution via the `resolveReviewThread` GraphQL mutation** performed by the bot
      (a reply alone does not resolve a thread); (d) the **obligatory CODEOWNERS +
      branch-protection gate with its bootstrapping guard** (committing CODEOWNERS is safe mid-run;
      activation is the final step).

- [x] 006: In the same `.workflow/README.md` section, add/verify the **cross-references** (AC-4
      tail + AC-5 of README): link to `docs/bot-credentials.md` (the canonical setup+rotation page)
      and to `.github/branch-protection.md` for the **story-003 activation command** and *when to
      flip the gate on* (only after this run's own PRs merge). Preserve the existing link to
      `.github/branch-protection.md` and CODEOWNERS; update the trailing
      "(Story 004 owns the fuller setup/rotation docs…)" note so it points at the now-expanded
      content and the canonical docs page.

- [x] 007: Coherence pass across the final docs set — read `docs/bot-credentials.md`,
      `.workflow/README.md`, `.github/branch-protection.md`, and the relevant
      `.claude/agents/independent-review.md` / `story-workflow.md` sections together and confirm **no
      two pages give conflicting setup/rotation/gate steps**: one canonical Keychain command form
      (`-a "$USER"`), one service name (`hana-review-bot`), one wrapper path
      (`scripts/gh-review-bot.sh`), one activation command source (`.github/branch-protection.md`).
      Fix any drift discovered.

- [x] 008: Verify **no secret leaks** in any doc authored/edited here (AC-5): grep the touched docs
      for token-shaped strings (`ghp_`, `github_pat_`) and confirm only human-run commands and the
      `hana-review-bot` service name appear. Confirm the secret-scan pre-commit hook is referenced
      as active (it is documented in `docs/bot-credentials.md`); no token value anywhere.

### Folded-in story-002 doc nits (touch `.claude/agents/*.md`)

- [x] 009: Make the bot-wrapper `gh pr review` examples in
      `.claude/agents/independent-review.md` consistently include `-R <owner/repo>` (deferred nit i).
      Lines ~74 (`scripts/gh-review-bot.sh gh pr review <number> --approve`) and ~79
      (`... --request-changes --body-file <body-file>`) currently omit `-R`; the COMMENT-fallback
      example (~131) already includes it. Add `-R <owner/repo>` to the formal-submission examples so
      all `gh pr …` invocations are repo-explicit and consistent. Mirror the same fix into the
      prose example at line ~153 and any equivalent `gh pr review` snippet in
      `.claude/agents/story-workflow.md` if present.

- [x] 010: Tighten the thread-resolution enumeration query in
      `.claude/agents/independent-review.md` (deferred nit ii): the `reviewThreads` enumeration
      (~lines 96-102) currently keeps every `isResolved == false` thread; it should **filter to
      bot-authored threads** (the review author the bot owns) before resolving, and the "addressed"
      precondition needs a **concrete, checkable signal documented** (e.g. an acknowledging reply
      from the implementer on the thread, or the implementer's resolution marker) rather than the
      vague "confirm each is addressed". Update the query/instructions to select threads authored by
      `Hanahuac-Bot` and spell out the checkable "addressed" signal.
