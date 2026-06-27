## Stories

Ordered by dependency. Stories 001 and 002 (driver `pinch` action + baked-in driver
verification) MUST land before Story 003, so the zoom-out fix is verified by the new
mechanism (feature sequencing constraint).

- [x] 001-driver-pinch-action: Add a `pinch` (zoom) action to the ui-walkthrough driver (AC4) — DONE (PR #195 merged)
- [x] 002-bake-driver-into-verify-agents: Bake `just ui-walkthrough` into verify-story/verify-feature as the default issue-hunting verification (AC1-AC3)
- [x] 003-mapquiz-zoomout-fix: Fix country map-quiz zoom-out cap and prove it with the pinch-enabled driver (AC5-AC6) — depends on 001 + 002
