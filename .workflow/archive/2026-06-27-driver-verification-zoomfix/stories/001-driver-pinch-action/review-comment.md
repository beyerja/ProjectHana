<!-- independent-review -->
## Independent review — Round 2: CHANGES_REQUESTED

Cold-context 4-eye review of the `pinch` action at head `b18a609`, re-verified against the story spec (`.workflow/stories/001-driver-pinch-action/spec.md`).

**Prior-round fix: confirmed correct & complete.** The default velocity is now scale-aware — `velocity = step.velocity ?? (scale < 1 ? -1 : 1)` — so the documented happy path (`{ "action": "pinch", "scale": 0.5 }`, zoom out) supplies a negative velocity and no longer raises `NSInvalidArgumentException`. README and doc-comment are synced with the implementation.

### Acceptance criteria
- AC1 — `UIActionType.pinch` + `UIActionStep.scale` (required) / `.velocity` (optional) decode: **met**.
- AC2 — pinch via `XCUIElement.pinch(withScale:velocity:)`, scale<1 out / scale>1 in: **met** for the happy path.
- AC3 — unresolvable *target* skipped (no crash), per-step artifacts continue: **met** for the unresolvable-target path; see blockers for adjacent inputs that still crash.
- AC4 — README documents `pinch` with scale semantics + example: **met**.
- AC5 — `just lint` / `just test` pass: deferred to the CI gate / code-owner-review step.

### Blocking (posted inline)
1. **Non-positive `scale` aborts the whole run.** `guard let scale` only rejects nil; a `scale` of `0`/negative reaches `pinch(withScale:velocity:)`, which requires `scale > 0` → `NSInvalidArgumentException`. With `continueAfterFailure = false` (line 17) this aborts the entire driver run, violating the spec invariant "no crash/no test failure … per-step artifacts continue." `scale: 0` is reachable — the README documents `scale` with no lower bound. (`UIDriverTests.swift:127`)
2. **Explicit `velocity: 0` aborts the run.** `step.velocity ?? …` only substitutes the scale-aware default when velocity is *nil*; an explicit `0` survives, and Apple requires a non-zero velocity → `NSInvalidArgumentException` → run aborts instead of skipping. The README advertises `velocity` as a writable field, so `0` is reachable. (`UIDriverTests.swift:130`)

Both trip the **same** exception class the previous round deemed blocking. The scale-aware default closed the common `scale < 1` path but left these adjacent inputs crashing, defeating the very invariant the fix was meant to protect. Suggested fixes (guard `scale > 0`; treat velocity `nil`-or-`0` as the direction-derived default) are in the inline comments.

### Non-blocking nit (posted inline)
- README Fields table's "Used by" column for `label`/`identifier` omits `pinch`, though pinch resolves a target by label/identifier. (`README.md:51`)

The formal `code-owner-review` merge-gate check is **not** set by this agent.
