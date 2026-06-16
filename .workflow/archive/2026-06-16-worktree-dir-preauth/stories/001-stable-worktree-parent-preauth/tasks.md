# Tasks — 001-stable-worktree-parent-preauth

- [x] T1: Empirically confirm which settings file/key grants directory access without a prompt.
      → `permissions.additionalDirectories` in `.claude/settings.local.json` (gitignored) suppresses the
      prompt for the whole parent. `git worktree` needs the parent dir to pre-exist (`mkdir -p`).
- [x] T2: Update orchestrator Step 0 — worktree at stable parent `../ProjectHana-worktrees/<slug>`.
- [x] T3: Update orchestrator Step 11 — teardown removes the per-slug subdir; parent persists.
- [x] T4: Added worktrees-parent absolute path to `additionalDirectories` in `settings.local.json`;
      tracked `settings.json` kept portable.
- [x] T5: Updated `.workflow/README.md` — new scheme, one-time directory-authorization setup, migration
      of live worktrees.
- [x] T6: Empirically verified — created real worktree `../ProjectHana-worktrees/_preauth-verify`,
      did Read + Write + Bash inside it with NO directory-access prompt (the new parent has no per-path
      allowlist entry, so the no-prompt access is attributable to `additionalDirectories`). Worktree torn
      down clean.
