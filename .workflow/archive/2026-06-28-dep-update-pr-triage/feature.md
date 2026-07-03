# Feature: Pre-story dependency-update PR triage

## Goal

Before a feature workflow starts working on its own user stories, automatically detect all open
dependency-update PRs (Dependabot / Renovate), resolve any conflicts, verify the build, post the
required `code-owner-review` gate check, and squash-merge them. This keeps `main` clean and
up-to-date before any feature branch work begins, so feature stories build on a stable base.

## Acceptance Criteria

- [ ] A new agent file `.claude/agents/triage-dep-prs.md` exists with a complete protocol for
      detecting, optionally fixing, reviewing, and merging dependency-update PRs.
- [ ] `feature-orchestrator.md` is updated to spawn `triage-dep-prs` as **Step 1** (after worktree
      setup, before `clarify-feature`), then runs `git -C <worktree> fetch origin && git -C
      <worktree> merge origin/main` to pull freshly-merged dep changes into the worktree branch
      before proceeding.
- [ ] **No dep PRs open:** the step is a no-op; the agent logs "no dep PRs found" and returns
      STATUS: DONE within a few seconds.
- [ ] **Dep PR — clean (no conflicts, tests pass):** the agent posts the `code-owner-review`
      success check on the PR head via `scripts/gh-review-bot.sh`, verifies the check posted with
      the correct `app_id` (`4144849`), and squash-merges the PR; `main` advances.
- [ ] **Dep PR — merge conflict:** the agent fetches the dep branch, rebases it onto the current
      `main` (preferring `main` for non-dependency files; preserving the version-bump changes in
      `Package.swift` / `Package.resolved`), force-pushes the resolved branch, then proceeds with
      CI verification, review check, and merge.
- [ ] **Dep PR — tests fail after rebase:** the agent attempts a minimal call-site fix, commits it
      to the dep branch, and pushes. If it cannot automatically fix the failure, the PR is skipped
      (see next criterion).
- [ ] **Dep PR — cannot auto-fix:** the PR is skipped; its URL and reason are appended to
      `.workflow/log.md` as a visible warning; the workflow continues to feature stories without
      blocking.
- [ ] Skipped dep PRs are surfaced in the agent's final STATUS output so the user knows to handle
      them manually.
- [ ] After the triage step completes, the worktree branch is merged onto the updated `main`
      (`git merge origin/main`) so all subsequent feature stories see the clean, post-triage base.
- [ ] The `code-owner-review` gate check is posted by the agent only after `just lint` and
      `just test` pass in the worktree — never on a broken build.

## Detection Criteria for Dependency-Update PRs

A PR qualifies for triage when **all** of the following are true:

1. PR is **open** and targets `main`.
2. PR author login contains `[bot]` (e.g. `dependabot[bot]`, `renovate[bot]`).
3. At least one of:
   - PR has label `dependencies`
   - PR branch name starts with `dependabot/`
   - PR branch name starts with `renovate/`

List qualifying PRs with:
```sh
gh pr list -R <owner/repo> --state open --json number,title,author,headRefName,labels \
  --jq '[.[] | select(
    (.author.login | contains("[bot]")) and
    ((.labels[].name == "dependencies") or
     (.headRefName | startswith("dependabot/")) or
     (.headRefName | startswith("renovate/")))
  )]'
```

## Constraints

- The new `triage-dep-prs` agent must use the **existing** `scripts/gh-review-bot.sh` wrapper for
  all bot-authenticated calls — never read or echo bot secrets directly.
- The `code-owner-review` gate check is the only required review step for dep PRs (no
  `independent-review` pass; dep bumps are automated and audited upstream).
- The agent must never block the entire feature workflow for a dep PR it cannot auto-fix — skip
  with a log entry and continue.
- Commit messages pushed to dep branches must be single-line or written via file + `git commit -F`
  (no heredocs, consistent with CLAUDE.md allowlistable-command-shapes rules).
- All `git` operations use `-C <path>` (no `cd &&` compounds).
- Lint and test (`just lint`, `just test`) must pass in the worktree before the review check is
  posted.
- The CI self-heal logic from `code-owner-review.md` applies here too: if the required CI contexts
  (`Build & Test`, `gitleaks`) are absent on the PR head after a push, close/reopen the PR to
  re-trigger CI and wait with `gh pr checks <n> --watch --fail-fast` before posting the gate check.
- The merge uses `gh pr merge --squash --delete-branch` (same as story PRs).
- If the bot credentials are absent (wrapper exits non-zero), the agent posts an informational
  comment as the plain `gh` user and records "gate check SKIPPED" in `.workflow/log.md`, consistent
  with the graceful-degradation pattern in `code-owner-review.md`.

## Out of Scope

- Running `triage-dep-prs` outside the feature-orchestrator context (e.g. as a standalone scheduled
  job) — this feature wires it into the orchestrator only.
- Reviewing dep PR *content* for security advisories or semantic correctness beyond "does the build
  pass" — upstream bots own that.
- Enabling Dependabot or Renovate on the repo — this feature assumes they may be active in the
  future; it is purely the triage consumer.
- The `independent-review` pass for dep PRs — explicitly excluded (see Constraints).
- Automatic fixups beyond call-site changes implied directly by the dep bump (e.g. no
  architectural refactors).
- Handling dep PRs that target branches other than `main`.
