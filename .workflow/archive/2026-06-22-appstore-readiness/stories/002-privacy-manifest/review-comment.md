<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh, cold-context 4-eye review of the privacy-manifest change. No blocking findings.

### Acceptance criteria — all met
- **Manifest exists + bundled via project.yml + xcodeproj regenerated** — `Hanahuac/PrivacyInfo.xcprivacy` added; `project.yml` declares it as an always-bundled `buildPhase: resources` entry and excludes it from the auto-enumerated `Hanahuac` source tree so it is not double-added. Regenerated `project.pbxproj` shows exactly one entry in each of the four sections (PBXBuildFile, PBXFileReference, group membership, Resources phase) — no duplicate Copy-Resources entry. ✓
- **No tracking / no collected data** — `NSPrivacyTracking = <false/>`, empty `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`. ✓
- **UserDefaults required-reason** — single `NSPrivacyAccessedAPITypes` entry: `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`. `plutil -lint` reports OK. ✓
- **Required-reason audit, independently re-verified in the worktree:**
  - File timestamp — the only `resourceValues` call (`ProgressBackup.swift:78`) queries `.isDirectoryKey` only, which is NOT a file-timestamp key, so `NSPrivacyAccessedAPICategoryFileTimestamp` correctly NOT declared. No `attributesOfItem` / `getattrlist` / `NSFileModificationDate` usage. ✓
  - Disk space — no `volumeAvailableCapacity*` usage. ✓
  - System boot time — no `systemUptime` / `mach_absolute_time` / `kern.boottime`. ✓
  - Active keyboard — no `UITextInputMode.activeInputModes`. ✓
  - UserDefaults — used widely (ActiveSetStore, KeyValueStore, PreferenceStore, ProgressMigrator, SyncCoordinator, StreakTracker, LanguageManager, several quiz views) → correctly declared. ✓
- **Builds + CI green** — "Build & Test" passes (the build copies resources and would fail on an invalid plist or inconsistent pbxproj). No new dependencies; no unused usage-description strings added. ✓

### Note on formal review state
The formal GitHub review state (`--approve` via the bot wrapper) was **SKIPPED** this round — the action was blocked by the local permission classifier before the wrapper ran. The verdict is carried by **STATUS: APPROVED**, which is the authoritative loop signal. Thread resolution: N/A (round 1, no prior bot-authored threads).

**Verdict: APPROVED.**
