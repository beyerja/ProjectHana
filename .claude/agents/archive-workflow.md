---
name: archive-workflow
description: Move the completed workflow state to .workflow/archive/<timestamp>-<slug>/ and reset .workflow/ for the next feature
---

**Telemetry — run at the very start (ignore errors):**
```
just log start archive-workflow "feature" || true
```

Derive the slug from `HANA_FEATURE_SLUG` if set (the shared run slug), else from `.workflow/feature.md`.

Move `.workflow/feature.md`, `.workflow/stories.md`, `.workflow/log.md`, `.workflow/stories/`, and `.workflow/telemetry/` into `.workflow/archive/<YYYY-MM-DD>-<slug>/`, preserving the directory structure.

**Never move or delete `.workflow/ui-walkthrough/`.** It is a PERMANENT, shipped capability (the
`just ui-walkthrough` driver's `README.md`, canonical `scripts/` — incl. the recipe default
`smoke.json` — and `demo/` evidence), NOT per-run tracking state. Deleting it breaks `just
ui-walkthrough` (its default points at `.workflow/ui-walkthrough/scripts/smoke.json`) and the
`verify-story`/`verify-feature` agents that depend on it. If this run produced timestamped
`.workflow/ui-walkthrough/<run>/` output worth keeping as evidence, *copy* (don't move) it into the
archive's own `ui-walkthrough/` subdir; the canonical `README.md` + `scripts/` + `demo/` stay put.

Leave `.workflow/` containing **only** `README.md` and the permanent `.workflow/ui-walkthrough/`
capability dir — move everything else (the per-run tracking state listed above) into the archive.

**Worktree note:** the live working set (feature.md, stories.md, log.md, stories/) is gitignored, so
only the `archive/<date>-<slug>/` you create here is tracked. Committing it on this run's feature branch
(orchestrator Step 10) carries the durable record to `main` via the PR — so it survives worktree
teardown. The shared telemetry sink lives in the primary checkout; copy (don't move) its records for
this run into the archive's `telemetry/` so the committed archive has the cross-run history, while the
live sink stays put for concurrent runs.

After moving, stage the whole change so no late writes are stranded:
```
git add -A .workflow
```
Then confirm `git status --porcelain .workflow` shows only staged entries. If any *unstaged*
`.workflow/` change remains — e.g. a per-story `log.md` or `status.md` line an agent appended after
the closing snapshot — stage it too. This prevents legitimate late appends from being orphaned as
uncommitted working-tree deltas (the gitignored `.workflow/telemetry/*.jsonl` sink is exempt and
won't appear).

Install the app to the user's Applications folder **only if** the feature modified Swift source files or UI. Skip for pure tooling/workflow/config-only features (check by reviewing `.workflow/feature.md` — if the Goal mentions only agent files, CI config, or workflow scripts, skip this step):
```
just install
```

Run (ignore errors):
```
just log end archive-workflow "feature" <R> <W> 0 <B> 0 "" || true
```

Output STATUS: DONE.
