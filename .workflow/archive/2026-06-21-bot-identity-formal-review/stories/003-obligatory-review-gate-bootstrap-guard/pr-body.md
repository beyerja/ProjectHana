## Goal

Make independent review OBLIGATORY: a code-owner approval from `@Hanahuac-Bot` is required before merge to `main`. The gate is bootstrapped by committing `.github/CODEOWNERS` plus a documented, ready-to-run `gh api` branch-protection activation command — without enabling the gate mid-run, so the workflow does not deadlock on its own un-reviewed PRs.

## Changes

- Add `.github/CODEOWNERS` assigning the repository (`* @Hanahuac-Bot`) to the bot as the required code owner.
- Commit a single, self-contained, copy-pasteable `gh api` branch-protection activation command in docs that enables protection on `main` requiring an approving code-owner review (allowlistable shape — JSON body via committed `--input <file>`, no `cd &&`, no heredoc payload).
- Mark the activation as the FINAL step to run only AFTER this run's own PRs are merged (explicit bootstrapping guard).
- Document that committing CODEOWNERS alone is safe mid-run — only branch protection enforces the gate.
- Cross-reference the activation command and guard from the workflow README so a human knows exactly when and how to flip the gate on.

## Test plan

- [ ] `.github/CODEOWNERS` is committed and assigns `* @Hanahuac-Bot`.
- [ ] The `gh api` activation command is committed, self-contained, and copy-pasteable (no `cd &&`, no heredoc; JSON body via `--input <file>` if needed).
- [ ] Docs clearly mark activation as the FINAL post-merge step (bootstrapping guard explicit).
- [ ] Doc note confirms committing CODEOWNERS is safe mid-run (no merge block until protection is on).
- [ ] Activation command and guard are cross-referenced from the workflow README.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
