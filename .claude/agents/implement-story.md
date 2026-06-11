---
name: implement-story
description: Implement all pending tasks for a story on a feature branch, running project checks after each commit
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start implement-story "<story-id>" || true
```
(derive `<story-id>` from the last path component of the story dir, e.g. `001-telemetry-infrastructure`)

Read `<story-dir>/tasks.md`. Ensure on branch `story/<story-id>` (create from main if needed).

For each unchecked task:
1. Implement following existing project patterns
2. Run project checks:
   ```sh
   set -o pipefail
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
   xcodebuild -project ProjectHana.xcodeproj -scheme ProjectHana \
     -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug test \
     2>&1 | tee /tmp/projecthana-test.log | grep -E "TEST SUCCEEDED|TEST FAILED|error:"
   grep -q "TEST SUCCEEDED" /tmp/projecthana-test.log || { echo "error: tests did not succeed" >&2; exit 1; }
   ```
3. Fix any failures and retry until clean
4. Commit with a clear message
5. Mark task checked in `tasks.md`

**SwiftData schema changes**
When adding or removing fields on an `@Model` type:
- Non-optional fields without a default value will crash on launch if the simulator's store is stale. Before running tests, wipe the store: in the simulator, long-press the app icon → Remove App (or `xcrun simctl uninstall booted <bundle-id>`). The app's `ModelContainer` catch block should already handle this in development, but the simulator must be clean.
- After any schema change, grep all existing tests that construct the changed model type and verify they pass the new required fields. Tests that create model instances and omit new non-optional properties will produce compiler errors; tests that rely on old default values (e.g. `hasGraduated: false`) may silently produce wrong results — audit those explicitly.
- If the story spec does not include a migration plan, use `ModelConfiguration(isStoredInMemoryOnly: true)` in tests so they never touch the on-disk store.

**Xcode project wiring (pbxproj)**
Every new `.swift` file must be added to `ProjectHana.xcodeproj/project.pbxproj`:
- Allocate the next sequential UUIDs (format `AA000001`, `AA000002`, …). Find the current max by grepping `AA0000` in the pbxproj.
- Add a `PBXBuildFile` entry (odd UUID) and a `PBXFileReference` entry (even UUID, or follow the existing even/odd pattern).
- Add the file reference to the correct `PBXGroup` (matching its folder path).
- Add the build file to the correct `PBXSourcesBuildPhase` (main target or test target).
- For resource files (JSON, assets): add to `PBXResourcesBuildPhase` instead.

**Avoid redeclaration before adding extensions**
Before adding a new `extension` on any existing type (model, enum, struct), grep the codebase for existing extensions and computed properties on that type:
```sh
grep -r "extension <TypeName>" ProjectHana/
```
If a property or method you are about to add already exists in another file, reuse it — do not redeclare it. Common culprits: `displayName`, `localizedName`, `color`, `iconName` on model types used in multiple views.

**iOS-only APIs**
Modifiers unavailable on macOS (`navigationBarTitleDisplayMode`, `textInputAutocapitalization`, etc.) must use the wrappers in `ProjectHana/Views/ViewExtensions.swift` rather than direct calls.

After all tasks are done:
6. Run `bash scripts/install-mac.sh` **only if** the story adds new Swift files, introduces new UI modifiers, or touches any API that could differ between iOS and macOS. Skip it for changes that are purely config, data, or logic with no new platform API calls — and note the skip in the telemetry notes. When in doubt, run it.

**Telemetry — run before appending to log.md:**
Count your tool calls in this run: R = Read calls, W = Write calls, E = Edit calls, B = Bash calls. Estimate total chars processed (sum of file sizes read + written). Then run (ignore errors):
```
bash scripts/agent-log.sh end implement-story "<story-id>" <R> <W> <E> <B> <est_chars> "<retries and notable issues>" || true
```

Append to `<story-dir>/log.md`: `<timestamp> implement-story: DONE — <tasks completed>, <issues if any>`.

Output STATUS: DONE.
