---
name: break-tasks
description: Break a user story into atomic implementation tasks by reading the story spec and inspecting the codebase
---

Requires: story directory path as input (e.g. `.workflow/stories/001-<slug>`).

**Telemetry — run at the very start (ignore errors):**
```
just log start break-tasks "<story-id>" || true
```

Read `<story-dir>/spec.md`. Inspect the codebase: CLAUDE.md if present, relevant source files, existing patterns.

Break the story into atomic, independently implementable tasks — each task is one focused change.

**Extension collision check**: if any task adds presentation helpers (computed properties like `displayName`, `color`, `iconName`) to an existing model or enum type, add a preceding task:
- `000: Audit existing extensions on <TypeName> — grep for "extension <TypeName>" across the project and note any properties that must be reused rather than re-declared`

If the story modifies an existing `@Model` type (SwiftData), insert a task immediately after the model-definition task: audit all existing tests that construct `<ModelName>` and update them for new required fields or changed defaults.

**Enum-case fan-out check**: if the story adds a `case` to an enum that has *exhaustive switches* or *per-case parallel fields* (the canonical one is `AppLocale` — a new locale needs a matching `nameXx`/`capitalXx` on **all four** geo models `Country`/`River`/`MountainRange`/`Sea`, a new arm in **every** exhaustive switch incl. `GeoModel+PackData.swift`, plus catalog/`project.yml`/pack wiring), then grep for *all* sites up front and make the model-field additions and the switch-arm additions **one task each, grouped so the set is added together** — not a single "update Country" task. A partial update (e.g. only `Country` got `nameXx`, the other three models and the switches did not) is a "switch must be exhaustive" compile failure, and it is exactly what an interrupted mid-story WIP leaves behind. Enumerating the full site list in tasks.md makes each unit self-consistent and surfaces the missing arms before they reach a build.

Initialise `<story-dir>/log.md` with a header line if it does not already exist:
```
# Log — <story-title>
```

Write `<story-dir>/tasks.md`:
```
## Tasks
- [ ] 001: <description>
- [ ] 002: <description>
```

Count tool calls (R/W/E/B) and estimate chars, then run (ignore errors):
```
just log end break-tasks "<story-id>" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `<story-dir>/log.md`: `<timestamp> break-tasks: DONE, <N> tasks`.

Output STATUS: DONE.
