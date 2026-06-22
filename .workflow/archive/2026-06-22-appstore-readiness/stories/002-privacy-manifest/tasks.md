## Tasks

- [x] 001: Audit the codebase for required-reason APIs. Confirm UserDefaults usage (ActiveSetStore / KeyValueStore / LanguageManager / StreakTracker / ProgressMigrator / SyncCoordinator). Confirm whether file-timestamp (modification/creation/contentModificationDate), disk-space (volumeAvailableCapacity*), system-boot-time (systemUptime / mach_absolute_time / kern.boottime), and active-keyboard (UITextInputMode.activeInputModes) APIs are used. Record the full audit result (with "none found" where applicable) verbatim so it can be pasted into the PR description. Preliminary finding: only UserDefaults is used; the lone resourceValues call queries .isDirectoryKey (not a timestamp), so file-timestamp/disk/boot/keyboard categories are NOT used.
- [x] 002: Create Hanahuac/PrivacyInfo.xcprivacy (XML plist) declaring NSPrivacyTracking=false, empty NSPrivacyTrackingDomains array, empty NSPrivacyCollectedDataTypes array, and an NSPrivacyAccessedAPITypes array containing ONLY the categories the audit (001) confirmed as used — at minimum NSPrivacyAccessedAPICategoryUserDefaults with NSPrivacyAccessedAPITypeReasons = [CA92.1]. Add no other categories or usage-description strings for unused APIs.
- [x] 003: Bundle the manifest via project.yml. Add Hanahuac/PrivacyInfo.xcprivacy as a resource on the Hanahuac app target (buildPhase: resources), keeping it in the always-bundled set (no resourceTags) and not excluded. Do NOT hand-edit the .xcodeproj.
- [x] 004: Regenerate the Xcode project with xcodegen (HANA_FEATURE_SLUG=appstore-readiness) via the worktree justfile, and confirm PrivacyInfo.xcprivacy is referenced in the regenerated project's Copy Resources build phase.
- [x] 005: Build and run lint/tests via the worktree justfile to confirm the app still compiles and CI-equivalent checks stay green with the manifest bundled under free signing.

## Audit result (verbatim, for PR description)

Required-reason API audit (codebase-wide):

- UserDefaults: USED — ActiveSetStore, KeyValueStore, PreferenceStore, LanguageManager, StreakTracker, ProgressMigrator, SyncCoordinator. Declared: NSPrivacyAccessedAPICategoryUserDefaults, reason CA92.1.
- File timestamp APIs (creation/modification/contentModificationDate): NONE FOUND. The only URLResourceValues call (ProgressBackup.swift) queries `.isDirectoryKey` only — not a timestamp key. Not declared.
- Disk space APIs (volumeAvailableCapacity*): NONE FOUND. Not declared.
- System boot time APIs (systemUptime / mach_absolute_time / kern.boottime): NONE FOUND. Not declared.
- Active keyboard APIs (UITextInputMode.activeInputModes): NONE FOUND. Not declared.
