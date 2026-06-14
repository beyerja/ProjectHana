# Feature: iCloud Progress Sync (CloudKit-ready)

## Goal
Let a user's learning progress follow them across their Apple devices via iCloud, so they can switch between iPhone, iPad, and Mac and continue where they left off.

**Important provisioning constraint:** The project currently has **no paid Apple Developer Program membership**, and every iCloud capability (CloudKit, `NSUbiquitousKeyValueStore`, iCloud Documents) requires one. A free/Personal signing team cannot enable any iCloud entitlement. Therefore this feature delivers a **CloudKit-ready architecture with an opt-in UI**, wired so that actual iCloud sync can be turned on by a single configuration flip once a paid account + iCloud container exist. The CloudKit container ships **disabled** by default and the sync code path is gated behind a compile-time/entitlement flag.

This means: we build and verify everything that does *not* require the entitlement (model compatibility, syncable stores, opt-in toggle, sync-status UI, abstraction layer, documentation). We explicitly do **not** claim that live cross-device syncing works, because it cannot be provisioned or verified yet.

## What syncs (once enabled)
- **Card state** — the SM-2 `ReviewCard` records (ease factor, intervals, next-review dates, graduation, streaks). Core progress.
- **Active learning set** — the per-category in-progress active set (currently `UserDefaultsActiveSetStore`).
- **Preferences** — user-facing app preferences (e.g. selected language).

## Acceptance Criteria
- [ ] `ReviewCard` is CloudKit-compatible: every stored attribute is optional or has a default value, there are no `@Attribute(.unique)` constraints, and any relationships (if added) are optional. Existing local persistence and tests still pass.
- [ ] Cross-device duplicate-seed safety: seeding/merge logic deduplicates `ReviewCard`s by `factID` so two devices independently seeding the same catalog converge to one card per fact (CloudKit forbids unique constraints).
- [ ] The active learning set is persisted in a sync-capable store (CloudKit-backed or `NSUbiquitousKeyValueStore`-backed) behind the existing `ActiveSetStore` protocol, with the `UserDefaults` implementation retained as the local/disabled-sync fallback.
- [ ] Preferences that should sync are persisted in a sync-capable store with a local fallback.
- [ ] A `ModelContainer`/sync-coordinator abstraction selects between local-only and CloudKit-backed configuration based on a single build/entitlement flag. With the flag off (default), behavior is identical to today's local-only app.
- [ ] An **opt-in** sync toggle exists in a settings surface. It is off by default. Toggling it persists the user's choice. When sync is unavailable (no entitlement / not signed into iCloud), the toggle communicates that sync is unavailable rather than silently failing.
- [ ] A sync-status indicator reflects the current state (e.g. off / unavailable / on; and when enabled later, syncing/idle/error).
- [ ] iCloud account sign-out or Apple ID change falls back to local-only data without crashing or data loss; this fallback path is covered by the abstraction and is testable.
- [ ] Conflict resolution relies on CloudKit's default last-writer-wins (no custom merge required).
- [ ] Documentation (in-repo) lists the exact steps to enable live sync once a paid account exists: enrollment, iCloud container creation, entitlements to add to `project.yml`, background-modes, and the flag to flip.
- [ ] The app builds and existing CI passes with the CloudKit path disabled (default).

## Constraints
- No paid Apple Developer account available now → iCloud entitlements cannot be enabled, signed, run, or verified. CloudKit path ships disabled behind a flag.
- SwiftUI · SwiftData · MapKit · **zero external dependencies** (maintain this — no third-party sync libraries).
- iOS 17+ / macOS 14+.
- Use Nix flake + direnv; never hardcode `/nix` paths.
- Conflict resolution: last-writer-wins (CloudKit default) is acceptable; no custom merge logic.

## Out of Scope
- Actually provisioning the iCloud container or enabling entitlements (requires paid account).
- End-to-end verification of live cross-device syncing (cannot be provisioned/tested yet).
- Custom/field-level conflict-merge logic beyond last-writer-wins.
- Non-Apple platforms or any non-iCloud sync backend.
- Account-management UI beyond the opt-in toggle, status indicator, and unavailable/sign-out messaging.
