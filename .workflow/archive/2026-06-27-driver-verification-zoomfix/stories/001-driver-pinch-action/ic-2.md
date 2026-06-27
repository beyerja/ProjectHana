**Blocking — an explicit `velocity: 0` aborts the run.** `step.velocity ?? (scale < 1 ? -1 : 1)` only substitutes the scale-aware default when `velocity` is *nil*; an explicit `0` is non-nil and survives the `??`. Apple requires a non-zero velocity, so `{ "action": "pinch", "scale": 0.5, "velocity": 0 }` raises `NSInvalidArgumentException` and (with `continueAfterFailure = false`) aborts the whole run instead of skipping — defeating the "artifact collection continues" design the scale-aware default was added to protect. Since the README advertises `velocity` as a writable field, `0` is reachable.

Consider falling back to the direction-corrected default when velocity is nil **or 0**, e.g.:

```suggestion
        let velocity = (step.velocity ?? 0) != 0 ? step.velocity! : (scale < 1 ? -1 : 1)
```
