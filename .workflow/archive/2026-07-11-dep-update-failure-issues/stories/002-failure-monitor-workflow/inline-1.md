**[blocking] Missing `concurrency:` group — duplicate-issue / duplicate-comment race (TOCTOU).**

The report step is check-then-act: it reads the open issue (`gh issue list`) and the already-reported run ids, then creates/comments. Nothing serializes monitor runs, and three triggers can overlap (a `workflow_run` event from a re-run of a failed "Update flake.lock" run, the daily 06:15 sweep, and manual dispatches). Two overlapping runs both see "no open issue" → **two open `dep-update-failure` issues** (permanently breaking the single-rolling-issue invariant — later runs only ever comment on `.[0]`), or both see run X unreported → **duplicate comment for the same run id**, violating the "never re-reported" acceptance criterion.

A workflow-level concurrency group serializes the whole job (a queued run superseded by a newer pending one is harmless — the daily sweep + dedup re-covers its report):

```suggestion
concurrency:
  group: dep-update-failure-monitor

permissions:
```
