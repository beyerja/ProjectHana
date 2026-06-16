# Story 001 — Stable worktree parent dir + pre-authorized directory access

## Goal

Relocate parallel-workflow worktrees from scattered siblings (`../ProjectHana-<slug>`) to a single
**stable parent directory** (`../ProjectHana-worktrees/<slug>`), and pre-authorize that one parent via
Claude Code's `permissions.additionalDirectories` so every current and future worktree under it is
accessible with **no per-worktree, per-run directory-access prompt**.

This is a single vertically-sliced story: the path relocation and the authorization must land together
to be coherent and verifiable — relocating without authorizing, or authorizing the old scattered scheme,
each leaves the workflow no better off.

## Scope of changes

- `.claude/agents/feature_orchestrator.md`
  - Step 0 (worktree creation): create worktrees at a stable parent `../ProjectHana-worktrees/<slug>`
    (mkdir -p the parent first), not `../ProjectHana-<slug>`.
  - Step 11 (teardown): remove `../ProjectHana-worktrees/<slug>`; prune; delete branch. Primary
    checkout must end clean.
- `.claude/settings.local.json` (gitignored, machine-specific): add the absolute worktrees-parent path
  to `permissions.additionalDirectories`. (Confirm empirically this is the file/key that grants access
  to spawned/background sub-agents; adjust if `settings.json` is required instead — but keep machine
  absolute paths out of the tracked `settings.json`.)
- `.claude/settings.json` (tracked, portable): fold in changes cleanly without clobbering any existing
  local modification; no machine-specific absolute paths.
- `.workflow/README.md`: update the parallel-worktrees section to document the new
  `../ProjectHana-worktrees/<slug>` scheme and the one-time directory-authorization setup.

## Acceptance Criteria

- [ ] An agent can read/write/run files inside a parallel worktree under the new scheme **without any
      per-worktree directory-access prompt** — verified empirically against a REAL worktree, not assumed.
- [ ] Authorization is configured **once** (a single parent dir) and automatically covers all current
      and future worktrees; starting a new parallel workflow needs no manual access approval.
- [ ] Orchestrator Step 0, Step 11, and `.workflow/README.md` are consistent with the new location scheme.
- [ ] The two currently-live worktrees (`ProjectHana-progress-statistics`,
      `ProjectHana-river-line-interruptions`) are unblocked, OR the change documents how to migrate
      already-created worktrees under the new authorization.
- [ ] No machine-specific absolute paths in tracked `.claude/settings.json`; those live in
      `.claude/settings.local.json`. Portable settings stay portable.
- [ ] Single-checkout and in-place/meta runs are unaffected.
- [ ] Authorization scope is the worktrees parent only — not a broad dir granting access to unrelated
      sibling repos.
