**Blocking — non-positive `scale` aborts the whole run.** `guard let scale` only rejects a *missing* scale; a `scale` of `0` or negative passes through to `element.pinch(withScale:velocity:)`. Apple requires `scale > 0`, so `{ "action": "pinch", "scale": 0 }` raises `NSInvalidArgumentException`. With `continueAfterFailure = false` (line 17) that aborts the entire driver run — violating the spec invariant "no crash/no test failure … per-step artifacts continue to be captured." The README documents `scale` with no positive lower bound, so a `0` is reachable from a valid-looking script.

```suggestion
        guard let scale = step.scale, scale > 0 else {
            return
        }
```

This is the same `NSInvalidArgumentException` class the previous round flagged as blocking; the scale-aware velocity default fixed the common `scale < 1` path but left this adjacent input tripping the identical crash.
