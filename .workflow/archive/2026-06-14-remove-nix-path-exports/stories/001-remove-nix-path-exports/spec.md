# Story 001: Remove redundant nix PATH exports from agent files and settings

## Title
Remove `export PATH="$HOME/.nix-profile/bin:$PATH"` from agent instructions and clean up settings.json

## Goal
Eliminate all defensive `export PATH="$HOME/.nix-profile/bin:$PATH"` instructions from `.claude/agents/*.md` files, and replace the corresponding `export PATH=* && gh ...` permission allow-rules in `.claude/settings.json` with direct `gh ...` rules. The environment already provides `~/.nix-profile/bin` via direnv + shell inheritance, so these exports are redundant.

## Context
- Affected agent files: `create-pr.md`, `verify-story.md`, `wait-for-ci.md`
- `create-pr.md` line 15: `export PATH="$HOME/.nix-profile/bin:$PATH"` before `git push`
- `verify-story.md` line 17: `export PATH="$HOME/.nix-profile/bin:$PATH"` before `git checkout main`
- `wait-for-ci.md` line 23 and 33: two occurrences plus a note telling agents to always prepend it
- `settings.json` has several `export PATH=* && gh ...` allow rules added to accommodate the pattern; these should be replaced with plain `gh ...` or `gh pr ...` rules

## Acceptance Criteria
- [ ] `create-pr.md`: `export PATH=...` line removed; `git push` invoked directly
- [ ] `verify-story.md`: `export PATH=...` line removed; `git checkout main && git pull origin main` invoked directly
- [ ] `wait-for-ci.md`: both `export PATH=...` occurrences removed; note "gh is at ~/.nix-profile/bin/gh; always prepend..." removed; `gh pr checks` and `gh run` commands invoked directly
- [ ] `.claude/settings.json`: `export PATH=* && gh ...` allow rules replaced with equivalent plain `gh ...` rules; no duplicate entries created
- [ ] No remaining `nix-profile/bin` PATH exports in any `.claude/agents/*.md` file
- [ ] `gh` is still in a permitted allow rule so agents can invoke it without prompts

## Test Plan
- `grep -rn 'export PATH.*nix-profile' .claude/agents/` returns no matches
- `grep -n 'nix-profile' .claude/agents/*.md` returns no matches (or only informational comments, not executable exports)
- `grep 'export PATH' .claude/settings.json` returns no matches (the export-PATH allow rules are gone)
- `gh pr list`, `gh pr checks`, `gh run list`, `gh run view`, `gh pr view`, `gh repo view` are still covered by allow rules
