<!-- code-owner-review -->
## Code owner review — APPROVED

Independently re-verified this diff (without re-running `/code-review`) and posted the required `code-owner-review` status check = **success** on head `c624dbd`.

**AC4 — pinch/zoom driver action:**
- `UIActionScript.swift`: new `.pinch` enum case + optional `scale`/`velocity` `Double?` fields — backward-compatible Codable.
- `UIDriverTests.swift`: `pinch(_:in:)` handler wired into the dispatch switch (the new seam reaches its production call site, so the AC is runtime-reachable). Guards `scale > 0` (skips otherwise); derives a correctly-signed default velocity from scale when absent/zero, satisfying the `XCUIElement.pinch(withScale:velocity:)` sign constraint; gracefully skips unresolvable targets and falls back to the whole app.
- `README.md`: docs accurately match the implemented behavior.

No correctness bugs, regressions, or unmet ACs. The `independent-review` APPROVED verdict still holds after the branch update with origin/main (l10n PRs #193/#194 — no file overlap). All required CI green on this head SHA.

The gate check is posted as the GitHub App (app id 4144849) via the wrapper, verified by read-back.
