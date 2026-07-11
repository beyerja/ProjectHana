**Nit (non-blocking): dedup has a race window without a `concurrency:` group.**

The list-then-create dedup is correct for the normal weekly cadence, but two overlapping runs (e.g. a `workflow_dispatch` fired while the scheduled run is mid-flight) can both see "no open issue" here and each create one — violating the "never a second open issue labeled `flake-lock-update`" invariant.

A workflow-level guard closes it:

```yaml
concurrency:
  group: update-flake-lock
  cancel-in-progress: false
```

Fine to defer; the overlap requires a manual dispatch timed inside a scheduled run's ~2-minute window.
