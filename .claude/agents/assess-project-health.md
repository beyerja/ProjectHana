---
name: assess-project-health
description: Audit the project for missing quality infrastructure and prepend setup stories to .workflow/stories.md
---

Inspect the project to determine what quality tooling is warranted but absent. Consider: testing framework, linting, formatting, type-checking, and CI — infer the appropriate tools from the project's language and platform.

For each gap found, prepend a setup story to `.workflow/stories.md` (numbered before existing stories) and create the corresponding `spec.md` and `status.md` in `.workflow/stories/<NNN>-<slug>/`.

If no gaps are found, do nothing.

Append to `.workflow/log.md`: `<timestamp> assess-project-health: DONE — <gaps found or "none">`.

Output STATUS: DONE.
