---
name: archive-workflow
description: Move the completed workflow state to .workflow/archive/<timestamp>-<slug>/ and reset .workflow/ for the next feature
---

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start archive-workflow "feature" || true
```

Read `.workflow/feature.md` to derive a slug from the feature name.

Move `.workflow/feature.md`, `.workflow/stories.md`, `.workflow/log.md`, and `.workflow/stories/` into `.workflow/archive/<YYYY-MM-DD>-<slug>/`, preserving the directory structure.

Leave `.workflow/` empty except for `README.md`.

Run (ignore errors):
```
bash scripts/agent-log.sh end archive-workflow "feature" <R> <W> 0 <B> 0 "" || true
```

Output STATUS: DONE.
