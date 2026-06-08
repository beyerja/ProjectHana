---
name: verify-feature
description: Verify the complete feature satisfies all acceptance criteria in .workflow/feature.md end-to-end
---

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start verify-feature "feature" || true
```

Read `.workflow/feature.md` acceptance criteria and all story specs for full scope context.

Run the full test suite. Exercise the feature end-to-end. Check each acceptance criterion explicitly.

- **All pass** → run (ignore errors): `bash scripts/agent-log.sh end verify-feature "feature" <R> <W> <E> <B> <est_chars> "DONE" || true`. Append to `.workflow/log.md`: `<timestamp> verify-feature: DONE`. Output STATUS: DONE.
- **Any fail** → run (ignore errors): `bash scripts/agent-log.sh end verify-feature "feature" <R> <W> <E> <B> <est_chars> "FAILED" || true`. List each failed criterion and identify which story is responsible.
  Output STATUS: FAILED: <criterion> — story <id>.
