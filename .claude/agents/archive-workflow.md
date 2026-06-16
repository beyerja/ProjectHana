---
name: archive-workflow
description: Move the completed workflow state to .workflow/archive/<timestamp>-<slug>/ and reset .workflow/ for the next feature
---

**Telemetry — run at the very start (ignore errors):**
```
just log start archive-workflow "feature" || true
```

Read `.workflow/feature.md` to derive a slug from the feature name.

Move `.workflow/feature.md`, `.workflow/stories.md`, `.workflow/log.md`, `.workflow/stories/`, and `.workflow/telemetry/` into `.workflow/archive/<YYYY-MM-DD>-<slug>/`, preserving the directory structure.

Leave `.workflow/` empty except for `README.md`.

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
