# iCloud Progress Sync — CloudKit-ready architecture

Hanahuac ships a **CloudKit-ready** sync architecture that is **disabled by default**. Today the
app builds and runs local-only under free (Personal Team) signing; no iCloud entitlement is
present, so live cross-device sync is **not** active and cannot be verified yet.

This document records the current shipped state and the exact, ordered steps to turn on live
iCloud sync once a **paid Apple Developer Program** membership and an iCloud container exist.

> Conflict policy: CloudKit's default **last-writer-wins**. No custom merge logic exists or is
> needed.

---

## Current shipped state (sync OFF)

- **Default build is local-only and byte-compatible with the pre-feature app.** The CloudKit code
  path is gated behind the `CLOUDKIT_SYNC` compile-time condition, which is **not** defined.
- **No iCloud entitlements** are in `project.yml`, so CI keeps building/testing under free signing.
- **Zero external dependencies** (SwiftUI · SwiftData · MapKit only) — no third-party sync library.
- The Settings screen shows an **opt-in iCloud Sync toggle** that is **off by default** and renders
  as **Unavailable** (disabled, with an explanatory note) because the CloudKit path is not compiled.

### Files and types that make up the architecture

| Concern | File | Type(s) |
| --- | --- | --- |
| Single enable flag + container id | `Hanahuac/Sync/SyncFeatureFlag.swift` | `SyncFeatureFlag` (`isCompiledIn`, `containerIdentifier`) |
| Status model + iCloud availability | `Hanahuac/Sync/SyncStatus.swift` | `SyncStatus`, `ICloudAvailabilityProviding`, `SystemICloudAvailabilityProvider` |
| Coordinator: container + store selection + status + sign-out fallback | `Hanahuac/Sync/SyncCoordinator.swift` | `SyncCoordinator` (`makeModelContainer()`, `makeActiveSetStore()`, `makePreferenceStore()`) |
| Key-value façade (local / ubiquitous / fake) | `Hanahuac/Sync/KeyValueStore.swift` | `KeyValueStore`, `UserDefaultsKeyValueStore`, `UbiquitousKeyValueStore`, `InMemoryKeyValueStore` |
| Syncable active set | `Hanahuac/Models/ActiveSetStore.swift` | `KeyValueActiveSetStore`, `makeUbiquitousActiveSetStore()`; `UserDefaultsActiveSetStore` = local fallback |
| Syncable preferences | `Hanahuac/Sync/PreferenceStore.swift` | `PreferenceStore`, `KeyValuePreferenceStore`, `makeLocalPreferenceStore()`, `makeUbiquitousPreferenceStore()` |
| CloudKit-compatible model + dedup | `Hanahuac/Models/ReviewCard.swift`, `Hanahuac/Store/CardStore.swift` | `ReviewCard` (all attributes optional/defaulted, no `@Attribute(.unique)`), `CardStore.deduplicate()`, duplicate-safe `seedIfNeeded(...)` |
| App wiring | `Hanahuac/HanahuacApp.swift` | delegates container creation to `SyncCoordinator.makeModelContainer()` and injects the coordinator |
| Settings UI | `Hanahuac/Views/Settings/SettingsView.swift`, `Hanahuac/Views/Settings/SyncStatusPresentation.swift` | opt-in toggle + status indicator |

**Why no `@Attribute(.unique)` on `factID`?** CloudKit forbids unique constraints, so two devices
can independently seed the same catalog. Uniqueness-per-fact is enforced in app logic:
`CardStore.deduplicate()` collapses duplicate `ReviewCard`s by `factID` (favoring the
most-progressed card), and `seedIfNeeded(...)` inserts only missing factIDs.

---

## Steps to enable live sync (requires a paid account)

### 1. Enroll in the Apple Developer Program (paid)
iCloud capabilities (CloudKit, `NSUbiquitousKeyValueStore`, iCloud Documents) require a paid
membership; a free/Personal team cannot enable any iCloud entitlement.

### 2. Create the iCloud CloudKit container
In the Apple Developer portal (or Xcode → Signing & Capabilities → iCloud), create a container.
The code already expects:

```
iCloud.com.hanahuac.app
```

(see `SyncFeatureFlag.containerIdentifier`). If you choose a different identifier, update that
constant.

### 3. Add entitlements to `project.yml` (NOT applied today)
Add an entitlements file and reference it from the `Hanahuac` target. Do **not** commit this to the
default build if you need CI to keep passing under free signing — apply it on the enablement branch.

Create `Hanahuac/Hanahuac.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.hanahuac.app</string>
    </array>
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)com.hanahuac.app</string>
    <key>aps-environment</key>
    <string>production</string>
</dict>
</plist>
```

Then wire it into the `Hanahuac` target in `project.yml` and add the compile flag:

```yaml
targets:
  Hanahuac:
    settings:
      base:
        # ...existing settings...
        CODE_SIGN_ENTITLEMENTS: Hanahuac/Hanahuac.entitlements
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: CLOUDKIT_SYNC
    entitlements:
      path: Hanahuac/Hanahuac.entitlements
```

### 4. Background Modes (CloudKit push)
For CloudKit to deliver remote changes, enable the **Remote notifications** background mode.
Because `GENERATE_INFOPLIST_FILE: YES` is used, add it via the generated Info.plist keys in
`project.yml`:

```yaml
        INFOPLIST_KEY_UIBackgroundModes: remote-notification
```

(Or add `UIBackgroundModes` → `remote-notification` to an explicit `Info.plist` if you switch off
generation.)

### 5. Flip the single flag
The one switch is the **`CLOUDKIT_SYNC`** compilation condition (step 3 above). When it is defined:
- `SyncFeatureFlag.isCompiledIn` becomes `true`,
- `SyncCoordinator.makeModelContainer()` builds a `ModelConfiguration(..., cloudKitDatabase:
  .private(SyncFeatureFlag.containerIdentifier))`,
- the coordinator selects the `NSUbiquitousKeyValueStore`-backed active-set/preference stores when
  the user has opted in and an iCloud account is available,
- the Settings toggle becomes enabled and the status indicator reports `Off`/`On` instead of
  `Unavailable`.

No other code changes are required.

### 6. Regenerate the Xcode project
After editing `project.yml`:

```sh
just generate
```

This re-runs xcodegen (via the Nix flake + direnv dev shell). Never hand-edit
`Hanahuac.xcodeproj/project.pbxproj`.

### 7. Verify post-enable (needs the paid account + two devices)
1. Sign both devices into the **same** Apple ID / iCloud account.
2. Launch on device A, make progress (review some cards, change active set / language).
3. Launch on device B; confirm progress converges (last-writer-wins).
4. Seed the catalog independently on both devices and confirm `CardStore.deduplicate()` collapses
   to exactly one `ReviewCard` per `factID`.
5. Sign out of iCloud on a device and confirm the app falls back to local-only data without
   crashing or data loss (handled by `SyncCoordinator` + `ICloudAvailabilityProviding`).

> This step **cannot** be performed without the paid account and is intentionally out of scope for
> the current build.

---

## What is intentionally NOT done here
- No iCloud container is provisioned and no entitlement is enabled in the committed `project.yml`.
- Live cross-device sync is neither enabled nor verified.
- No custom/field-level conflict-merge logic (last-writer-wins only).
