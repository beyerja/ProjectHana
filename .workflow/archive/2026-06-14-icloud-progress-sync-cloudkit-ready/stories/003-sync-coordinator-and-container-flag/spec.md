# Story 003 — Sync coordinator + ModelContainer/flag abstraction (default OFF)

## Title
Single build/entitlement flag selects local-only vs CloudKit-backed configuration; sync
coordinator wires container + store selection + status + sign-out fallback

## Goal
Introduce the seam that, based on **one** flag, selects between the local-only
`ModelContainer`/store configuration (today's behavior) and a CloudKit-backed one — without
enabling any entitlement. With the flag OFF (the default, and the only state buildable/CI-able
under free signing), the app behaves exactly as today: local SwiftData store, `UserDefaults`
active-set + preferences. The CloudKit-backed branch is written and compiles, but is gated and
never taken by default.

## Acceptance Criteria
- [ ] A single source-of-truth flag (e.g. `SyncFeatureFlag` reading a compile-time condition
      like `#if CLOUDKIT_SYNC` and/or a runtime "iCloud available + user opted in" check)
      determines whether CloudKit configuration is eligible. Default = OFF / not compiled in.
      The flag is documented as the one thing to flip once a paid account exists.
- [ ] A `SyncCoordinator` (or `ModelContainerFactory`) builds the `ModelContainer`:
      - flag OFF → `ModelConfiguration(... isStoredInMemoryOnly: false)` exactly as
        `HanahuacApp` does today (no `cloudKitDatabase`).
      - flag ON → a configuration that *would* attach a CloudKit container
        (`ModelConfiguration(..., cloudKitDatabase: .private("iCloud.<container>"))` or the
        SwiftData equivalent), compiled behind `#if CLOUDKIT_SYNC` so the default build never
        references an entitlement-bound API. `HanahuacApp` delegates container creation to it.
- [ ] The coordinator also selects which `ActiveSetStore` / preference store to inject
      (ubiquitous when sync on+available, local otherwise), reusing Story 002's types.
- [ ] Sync availability + status: the coordinator exposes an observable status
      (`off` / `unavailable` / `on` and forward-compatible `syncing` / `idle` / `error`) and a
      way to detect iCloud account availability (e.g. `FileManager.ubiquityIdentityToken`) so a
      sign-out / Apple-ID change resolves to `unavailable` and the app falls back to local-only
      data **without crashing or data loss**. This fallback path is covered by the abstraction
      and is unit-testable with injected/faked availability.
- [ ] Conflict resolution = CloudKit default last-writer-wins; no custom merge logic added.
- [ ] Unit tests: flag OFF yields local config + local stores; faked "iCloud unavailable"
      yields `unavailable` status + local fallback (no crash); opt-in persisted choice is read
      by the coordinator; status transitions are observable. Tests must not require an
      entitlement or live iCloud.
- [ ] Default build (flag off) is byte-compatible with today; all existing tests pass; CI
      build/test pass. `project.yml` is NOT given iCloud entitlements (that stays documented as
      a manual enable step in Story 005).

## Out of Scope
- The settings toggle/status *UI* (Story 004) — this story exposes the model/state it binds to.
- Adding entitlements to `project.yml` (Story 005 documents how; we do NOT enable them).
- Live sync verification (impossible without a paid account).

## Notes
- Files: new `Hanahuac/Sync/` (coordinator, flag, status), `Hanahuac/HanahuacApp.swift`
  (delegate container creation), tests under `HanahuacTests/`.
- The whole point: flipping the flag + adding the entitlement (per Story 005 docs) is all
  that's needed to go live later. Keep that switch genuinely single-point.
- Zero external dependencies.
