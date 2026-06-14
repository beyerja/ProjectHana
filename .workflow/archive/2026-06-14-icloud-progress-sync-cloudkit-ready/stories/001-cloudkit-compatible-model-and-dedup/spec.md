# Story 001 — CloudKit-compatible ReviewCard model + dedup-by-factID

## Title
Make `ReviewCard` CloudKit-compatible and make seeding/merge dedup by `factID`

## Goal
Bring the SwiftData model and the seeding/merge logic into conformance with CloudKit's
schema rules, so the *same* model can later back a CloudKit container with no further
model changes. This is pure local work — no entitlements, no sync code.

CloudKit requires (for any `@Model` it will later mirror):
- every stored attribute is **optional or has a default value**
- **no** `@Attribute(.unique)` constraints
- any relationships (if present) are **optional** (and to-many must be optional)

Because CloudKit forbids unique constraints, two devices that independently seed the
same catalog can each create a `ReviewCard` for the same `factID`. Seeding/merge logic
must therefore converge to **one card per factID** via app-level dedup keyed on `factID`.

## Acceptance Criteria
- [ ] Every stored property on `ReviewCard` is optional or has a default value at the
      SwiftData layer (CloudKit-compatible). Audit `lastQualityScore` (already optional)
      and all non-optional scalars; give them model-level defaults where CloudKit needs
      them. Document the rationale inline.
- [ ] No `@Attribute(.unique)` anywhere on `ReviewCard`. (Confirm none exist; keep it that
      way and add a code comment explaining why uniqueness is enforced in app logic.)
- [ ] `CardStore` exposes/uses dedup-by-`factID`: a `deduplicate()` (or merge) routine that,
      given multiple `ReviewCard`s sharing a `factID`, keeps one canonical card and removes
      the duplicates. Deterministic winner selection (e.g. most-progressed / newest
      `nextReviewDate` / lowest `id`) documented in code.
- [ ] `seedIfNeeded` (and any merge path) is duplicate-safe: seeding when cards for some
      factIDs already exist does NOT create a second card for those factIDs. Seeding becomes
      "insert missing factIDs only," not "insert everything if store is empty."
- [ ] New unit tests in `HanahuacTests` cover: (a) dedup collapses duplicates by factID to a
      single card and preserves the most-progressed state, (b) re-seeding an already-seeded
      (or partially-seeded) store adds no duplicates, (c) seeding an empty store still
      produces exactly one card per catalog fact.
- [ ] All existing tests still pass; local persistence behavior is unchanged for the
      default (single-device, no-sync) case.
- [ ] App still builds (Mac Catalyst, ad-hoc signing) and CI-equivalent build/test pass.

## Out of Scope
- Any CloudKit configuration, entitlement, or sync container wiring (later stories).
- The sync toggle / status UI.

## Notes
- Files: `Hanahuac/Models/ReviewCard.swift`, `Hanahuac/Store/CardStore.swift`,
  `HanahuacTests/CardStoreTests.swift` (+ new test file if cleaner).
- Keep zero external dependencies. SwiftData + Foundation only.
