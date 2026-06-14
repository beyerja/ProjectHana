## Tasks
- [x] 001: Remove `export PATH="$HOME/.nix-profile/bin:$PATH"` from `create-pr.md` (line 15, before `git push`)
- [x] 002: Remove `export PATH="$HOME/.nix-profile/bin:$PATH"` from `verify-story.md` (line 17, before `git checkout main`)
- [x] 003: Remove both `export PATH=...` occurrences and the note "gh is at ~/.nix-profile/bin/gh; always prepend..." from `wait-for-ci.md`
- [x] 004: Update `.claude/settings.json` — replace `export PATH=* && gh ...` allow rules with direct `gh ...` equivalents and remove duplicates
