---
name: evaluate-workflow
description: Analyze the completed workflow execution and improve agent files in .claude/agents/ based on observed inefficiencies
---

Read `.workflow/log.md` and every `<story-dir>/log.md`.

Analyze:
- Revision cycle count per story (re-implementations, review iterations)
- Task size (too large = multi-session, too small = excessive overhead)
- Where verification failures were caught (late = weak earlier agents)
- Any repeated patterns of rework

Read all files in `.claude/agents/`.

Identify up to 3 concrete, high-impact improvements. For each: edit the relevant agent file directly with the improvement. Prefer targeted, surgical changes over rewrites.

Append to `.workflow/log.md`:
```
<timestamp> evaluate-workflow: DONE
Improvements: <list>
```

Output STATUS: DONE with a brief summary of what changed and why.
