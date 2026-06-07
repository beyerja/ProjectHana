---
name: verify-feature
description: Verify the complete feature satisfies all acceptance criteria in .workflow/feature.md end-to-end
---

Read `.workflow/feature.md` acceptance criteria and all story specs for full scope context.

Run the full test suite. Exercise the feature end-to-end. Check each acceptance criterion explicitly.

- **All pass** → append to `.workflow/log.md`: `<timestamp> verify-feature: DONE`. Output STATUS: DONE.
- **Any fail** → list each failed criterion and identify which story is responsible.
  Output STATUS: FAILED: <criterion> — story <id>.
