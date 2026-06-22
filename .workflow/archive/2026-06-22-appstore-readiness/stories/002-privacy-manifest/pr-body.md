## Goal

Add the Apple privacy manifest the App Store now requires, declaring that the app does no tracking and collects no data, and declaring the required-reason APIs the app actually uses.

## Summary of changes

- Adds `PrivacyInfo.xcprivacy` declaring **no tracking**:
  - `NSPrivacyTracking = false`
  - empty `NSPrivacyTrackingDomains`
  - empty `NSPrivacyCollectedDataTypes`
- Declares the **UserDefaults** required-reason API: `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`.
- Wires the manifest as a bundled app-target resource via `project.yml` and regenerates the `.xcodeproj` with `xcodegen`.

## Required-reason API audit

- **UserDefaults — USED** (declared, `CA92.1`). Used across `ActiveSetStore`, `KeyValueStore`, `PreferenceStore`, `ProgressMigrator`, `SyncCoordinator`, `StreakTracker`, `LanguageManager`, and several quiz views.
- **File timestamp** (`NSPrivacyAccessedAPICategoryFileTimestamp`) — **NONE found**. The only `resourceValues` call (`ProgressBackup.swift`) queries `.isDirectoryKey` only, not modification/creation timestamps.
- **Disk space** (`NSPrivacyAccessedAPICategoryDiskSpace`) — **NONE found** (no `volumeAvailableCapacity*` usage).
- **System boot time** (`NSPrivacyAccessedAPICategorySystemBootTime`) — **NONE found** (no `systemUptime` / `mach_absolute_time` / `kern.boottime` usage).
- **Active keyboard** — **NONE found** (no `UITextInputMode.activeInputModes` usage).
- **Conclusion:** only UserDefaults declared.

## Test plan

- [x] Lint passes
- [x] Tests pass
- [x] Builds under free signing
