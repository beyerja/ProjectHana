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
   - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ProjectHana.xcodeproj -scheme ProjectHana -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug test 2>&1 | grep "TEST SUCCEEDED\|TEST FAILED\|error:"`
3. Fix any failures and retry until clean
4. Commit with a clear message
5. Mark task checked in `tasks.md`

**Xcode project wiring (pbxproj)**
Every new `.swift` file must be added to `ProjectHana.xcodeproj/project.pbxproj`:
- Allocate the next sequential UUIDs (format `AA000001`, `AA000002`, …). Find the current max by grepping `AA0000` in the pbxproj.
- Add a `PBXBuildFile` entry (odd UUID) and a `PBXFileReference` entry (even UUID, or follow the existing even/odd pattern).
- Add the file reference to the correct `PBXGroup` (matching its folder path).
- Add the build file to the correct `PBXSourcesBuildPhase` (main target or test target).
- For resource files (JSON, assets): add to `PBXResourcesBuildPhase` instead.

**iOS-only APIs**
Modifiers unavailable on macOS (`navigationBarTitleDisplayMode`, `textInputAutocapitalization`, etc.) must use the wrappers in `ProjectHana/Views/ViewExtensions.swift` rather than direct calls.

After all tasks are done:
6. Run `bash scripts/install-mac.sh` from the repo root to build a macOS Release build and install it to `/Applications/ProjectHana.app`. Fix any macOS-specific build errors before proceeding.

**Telemetry — run before appending to log.md:**
Count your tool calls in this run: R = Read calls, W = Write calls, E = Edit calls, B = Bash calls. Estimate total chars processed (sum of file sizes read + written). Then run (ignore errors):
```
bash scripts/agent-log.sh end implement-story "<story-id>" <R> <W> <E> <B> <est_chars> "<retries and notable issues>" || true
```

Append to `<story-dir>/log.md`: `<timestamp> implement-story: DONE — <tasks completed>, <issues if any>`.

Output STATUS: DONE.
