**Nit (non-blocking): a `workflow_dispatch` from a non-default ref would force-push that ref's entire content to the handoff branch.**

`HEAD:automated/update-flake-lock` pushes whatever ref the run checked out. Scheduled runs always use the default branch, but `workflow_dispatch` lets a caller pick any branch — dispatching from a feature branch would overwrite `automated/update-flake-lock` with the whole feature-branch diff plus the lock bump, and the handoff issue would then present that as a "flake.lock update ready for triage".

Human review at PR time still catches it, so not blocking, but a job-level guard makes the contract explicit:

```yaml
if: github.ref == 'refs/heads/main' || github.event_name == 'schedule'
```
