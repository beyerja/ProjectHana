# Feature: Remove redundant nix PATH exports from agent files

## Goal
Remove the `export PATH="$HOME/.nix-profile/bin:$PATH"` lines from all `.claude/agents/*.md` files and update `settings.json` permissions accordingly, so that agents rely on the already-loaded environment (direnv + justfile) rather than defensive PATH manipulation.

## Background / Root Cause
Three agent files (`create-pr.md`, `verify-story.md`, `wait-for-ci.md`) instruct agents to prepend `~/.nix-profile/bin` to PATH before running `gh` or `git` commands. Investigation shows:

1. The `.envrc` already calls `PATH_add "$HOME/.nix-profile/bin"`, so direnv loads the nix profile into PATH when the project directory is entered.
2. The `justfile` also exports `PATH := env_var("HOME") + "/.nix-profile/bin:" + env_var("PATH")` at the top level, meaning any `just` invocation automatically gets the nix tools.
3. Claude Code's Bash tool inherits the shell environment from the parent process (verified: `which gh` resolves to `/Users/Private/.nix-profile/bin/gh` without any export needed).
4. The `export PATH=` lines in agent files were written defensively, before or alongside the flake/direnv setup — they are now redundant.
5. `settings.json` permission allow-rules also encode `export PATH=* && gh ...` patterns; these must be replaced with simpler `gh ...` patterns to match the cleaned-up agent commands.

## Acceptance Criteria
- [ ] `create-pr.md`: `export PATH=...` line is removed; `git push` command has no PATH prefix; `gh pr create` command has no PATH prefix
- [ ] `verify-story.md`: `export PATH=...` line is removed; `git checkout main && git pull origin main` has no PATH prefix
- [ ] `wait-for-ci.md`: both `export PATH=...` lines and the note "gh is at ~/.nix-profile/bin/gh; always prepend..." are removed; commands use plain `gh pr checks` and `gh run` without PATH prefix
- [ ] `settings.json` permissions are updated: `export PATH=* && gh ...` allow rules are replaced with direct `gh ...` rules (or consolidated where duplicates exist)
- [ ] No other agent files introduce new `export PATH=...nix-profile...` lines
- [ ] `gh` and `git` commands still work correctly in agent contexts after the change (PATH is already present via direnv / shell inheritance)

## Constraints
- Do not change how `just` works — the justfile already handles PATH and that is fine
- Do not change `.envrc` or `flake.nix`
- Fix should be generic: address every current occurrence and leave no instruction to add it back
- The `settings.json` allow rules for `export PATH=* && ...` that are now unused should be removed or replaced with direct equivalents to keep the allowlist clean

## Out of Scope
- Changing CI/GitHub Actions workflows
- Modifying how direnv is set up or the Nix flake inputs
- Adding CLAUDE.md (not present in project and not requested)
- Any app feature changes
