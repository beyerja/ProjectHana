# Story 002 — Syncable active-set + preferences stores with local fallback

## Title
Put active learning set and syncable preferences behind a sync-capable store abstraction
with a `UserDefaults` local fallback

## Goal
The active learning set (`ActiveSetStore`) and the syncable user preference(s)
(selected language in `LanguageManager`) must each be persisted through an abstraction
that can be backed by a sync-capable store (`NSUbiquitousKeyValueStore`) when sync is on,
and falls back to the existing local `UserDefaults` implementation when sync is off or
unavailable. With sync OFF (the default), behavior is byte-for-byte identical to today.

This story builds the store implementations and selection seam ONLY. The actual
"is sync enabled?" decision is owned by the sync coordinator (Story 003); here we expose
constructor/selection points the coordinator can drive, defaulting to local.

## Acceptance Criteria
- [ ] `ActiveSetStore` protocol is unchanged in shape. A new
      `UbiquitousActiveSetStore` (backed by `NSUbiquitousKeyValueStore`) conforms to it,
      mirroring the key scheme of `UserDefaultsActiveSetStore`. It must compile and be
      unit-testable without any iCloud entitlement (the type exists and is exercised against
      an injectable key-value façade; it is simply never selected while sync is off).
- [ ] The existing `UserDefaultsActiveSetStore` is retained as the local/disabled-sync
      fallback and remains the default.
- [ ] Syncable preferences: introduce a small `PreferenceStore` (or equivalent) seam so the
      synced preference (selected `AppLocale`) reads/writes through a protocol with a
      `UserDefaults`-backed local fallback and a `NSUbiquitousKeyValueStore`-backed
      implementation. `LanguageManager` uses the injected store; default injection is the
      local `UserDefaults` one, preserving current behavior exactly.
- [ ] A shared, injectable key-value abstraction lets the ubiquitous-backed stores be tested
      with an in-memory fake (no entitlement needed). Avoid hard dependence on a live
      `NSUbiquitousKeyValueStore` in tests.
- [ ] Unit tests: ubiquitous-backed stores round-trip values through the fake; local
      fallback stores still round-trip; `LanguageManager` persists/restores selection through
      the injected store; switching the injected store type does not change observable API.
- [ ] All existing tests pass. Default app behavior (sync off) unchanged.
- [ ] Builds + CI-equivalent build/test pass.

## Out of Scope
- The coordinator/flag that decides which store to inject (Story 003).
- The toggle UI (Story 004).
- Any entitlement edits to `project.yml`.

## Notes
- Files: `Hanahuac/Models/ActiveSetStore.swift`,
  `Hanahuac/L10n/LanguageManager.swift`, new store/abstraction files under
  `Hanahuac/Store/` or `Hanahuac/Sync/`, tests under `HanahuacTests/`.
- `NSUbiquitousKeyValueStore` itself needs no entitlement to *reference* in code; it only
  syncs at runtime when the iCloud Key-Value entitlement is present. Referencing/instantiating
  it must not break the local-only build. Keep it behind the protocol so tests use the fake.
- Zero external dependencies.
