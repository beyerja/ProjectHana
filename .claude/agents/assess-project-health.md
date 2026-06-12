---
name: assess-project-health
description: Audit the project for missing quality infrastructure and prepend setup stories to .workflow/stories.md
---

**Telemetry — run at the very start (ignore errors):**
```
just log start assess-project-health "feature" || true
```

Inspect the project to determine what quality tooling is warranted but absent. Consider: testing framework, linting, formatting, type-checking, and CI — infer the appropriate tools from the project's language and platform.

For each gap found, prepend a setup story to `.workflow/stories.md` (numbered before existing stories) and create the corresponding `spec.md` and `status.md` in `.workflow/stories/<NNN>-<slug>/`.

If no gaps are found, do nothing.

Run (ignore errors):
```
just log end assess-project-health "feature" <R> <W> 0 <B> <est_chars> "" || true
```

Append to `.workflow/log.md`: `<timestamp> assess-project-health: DONE — <gaps found or "none">`.

Output STATUS: DONE.
