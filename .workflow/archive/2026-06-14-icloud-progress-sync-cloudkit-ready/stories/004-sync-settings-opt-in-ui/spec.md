# Story 004 — Opt-in sync toggle + status indicator in a Settings surface

## Title
Settings surface with an opt-in iCloud Sync toggle (off by default) and a sync-status indicator

## Goal
Give the user a place to opt into iCloud sync and see its state. The toggle is OFF by
default, persists the user's choice, and clearly communicates when sync is *unavailable*
(no entitlement / not signed into iCloud) instead of silently failing. The status indicator
reflects `off` / `unavailable` / `on` (and is forward-compatible with `syncing` / `idle` /
`error` once live sync exists). Bind to Story 003's coordinator/status; do not implement sync
itself.

## Acceptance Criteria
- [ ] A Settings screen exists (introduce `SettingsView` reached from the existing gearshape
      toolbar item in `HomeView`, with the language picker accessible from it — do not regress
      language selection). The gearshape may now open `SettingsView` rather than going straight
      to the language picker.
- [ ] An "iCloud Sync" opt-in toggle:
      - OFF by default.
      - Toggling persists the user's choice (through the preference/coordinator seam, not a
        bare ad-hoc UserDefaults key duplicated elsewhere).
      - When sync is unavailable (flag not compiled / no iCloud account), the toggle is
        disabled or shows an explanatory "iCloud sync unavailable" message; it must NOT appear
        to silently succeed.
- [ ] A sync-status indicator reflects current state: `off`, `unavailable`, `on` (+ room for
      `syncing`/`idle`/`error`). Driven by the coordinator's observable status.
- [ ] Localized strings for the new UI added to all four `.lproj` Localizable.strings
      (en, fr, de, es-MX), consistent with existing `settings.*` keys.
- [ ] In the default build (CloudKit path not compiled), the toggle presents as
      unavailable/off and turning it on does not crash and does not falsely claim sync is
      active.
- [ ] A SwiftUI `#Preview` exists for the new Settings/toggle view. Existing tests pass; add
      light tests for any view-model/state logic introduced (e.g. status-to-label mapping).
- [ ] Builds + CI-equivalent build/test pass.

## Out of Scope
- Implementing the sync engine (Story 003 owns the coordinator/state).
- Enabling entitlements (Story 005 documents).
- Account-management UI beyond the toggle, status, and unavailable/sign-out messaging.

## Notes
- Files: new `Hanahuac/Views/Settings/SettingsView.swift` (+ optional small view-model),
  `Hanahuac/Views/Home/HomeView.swift` (route gear to Settings),
  four `Localizable.strings`, tests under `HanahuacTests/`.
- Depends on Story 003's coordinator/status existing.
- Zero external dependencies.
