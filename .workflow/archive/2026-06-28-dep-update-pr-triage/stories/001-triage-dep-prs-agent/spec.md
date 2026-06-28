# Story 001 — triage-dep-prs agent

## Title
Write the `triage-dep-prs` agent

## Goal
Create `.claude/agents/triage-dep-prs.md` — a self-contained sub-agent that detects all open
dependency-update PRs (Dependabot / Renovate), resolves merge conflicts where possible, verifies
the build, posts the `code-owner-review` gate check via `scripts/gh-review-bot.sh`, and squash-
merges each qualifying PR. PRs it cannot auto-fix are skipped with a log entry; the agent never
blocks the workflow for unfixable dep PRs.

## Acceptance Criteria

- [ ] `.claude/agents/triage-dep-prs.md` exists in the primary checkout.
- [ ] The agent frontmatter names it `triage-dep-prs` and carries a clear one-line description.
- [ ] **Detection:** the agent uses the `gh pr list` jq filter from the feature spec to enumerate
      open PRs authored by a `[bot]` login that carry a `dependencies` label or a
      `dependabot/` / `renovate/` branch-name prefix.
- [ ] **No dep PRs:** the agent logs "no dep PRs found" and exits `STATUS: DONE` immediately,
      without touching any branch or posting any check.
- [ ] **Clean PR (no conflicts, CI green):** the agent posts the `code-owner-review` success check
      on the PR head via the wrapper (`scripts/gh-review-bot.sh`), verifies the posted check's
      `app.id` equals `4144849`, and squash-merges the PR with
      `gh pr merge --squash --delete-branch`.
- [ ] **Merge conflict:** the agent fetches the dep branch, rebases it onto `main` (preserving
      version-bump changes in `Package.swift` / `Package.resolved`; preferring `main` for all
      other conflict sides), force-pushes the resolved branch, then proceeds through CI
      verification → review check → merge.
- [ ] **Tests fail after rebase:** the agent attempts a minimal call-site fix, commits it to the
      dep branch (message written to a file + `git commit -F`; no heredocs), and pushes. If the
      fix attempt fails, it falls through to the skip path.
- [ ] **Cannot auto-fix:** the PR URL and reason are appended to `.workflow/log.md`; the agent
      continues to the next dep PR without blocking.
- [ ] The agent's final STATUS output lists all skipped PRs so the user knows what needs manual
      attention.
- [ ] The `code-owner-review` gate check is posted **only after** `just lint` and `just test`
      pass in the repo root — never on a broken build.
- [ ] CI self-heal: if the required CI contexts (`Build & Test`, `gitleaks`) are absent on the
      PR head after a push, the agent closes/reopens the PR to re-trigger CI and waits with
      `gh pr checks <n> --watch --fail-fast` before posting the gate check.
- [ ] Graceful degradation: if the wrapper exits non-zero (creds absent), the agent posts an
      informational comment as the plain `gh` user, records "gate check SKIPPED" in
      `.workflow/log.md`, and continues.
- [ ] All git operations use `-C <path>` (no `cd &&` compounds); commit messages use
      `git commit -F <file>` (no heredocs or `$(…)` payloads).
- [ ] Telemetry: the agent runs `just log start triage-dep-prs ...` at the top and
      `just log end triage-dep-prs ...` before exiting, ignoring errors from both.
