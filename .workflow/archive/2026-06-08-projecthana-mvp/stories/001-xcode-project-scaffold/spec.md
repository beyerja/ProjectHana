# Story 001: Xcode Project Scaffold

## Title
Set up the Xcode project with SwiftUI, SwiftData, iOS 17+ / macOS 14+ targets

## Goal
Create a compiling Xcode project with the correct deployment targets, bundle structure, and basic
app entry point so every subsequent story has a working foundation to build on.

## Acceptance Criteria
- [ ] Xcode project named `ProjectHana` exists at the repo root with a single `App` target
- [ ] Deployment target: iOS 17.0 minimum; macOS 14.0 via Mac Catalyst enabled
- [ ] Bundle identifier: `com.projecthana.app`
- [ ] App compiles and launches to a placeholder `ContentView` showing "ProjectHana" text
- [ ] SwiftData `ModelContainer` is configured in the `@main` App struct (even if no models yet)
- [ ] `xcodebuild build` succeeds with zero warnings treated as errors (or at most minor SwiftUI
      preview warnings suppressed via build settings)
- [ ] `.gitignore` updated to exclude `*.xcuserstate`, `DerivedData/`, and other Xcode noise
- [ ] Project uses Swift Package resolved file (empty, no external deps) committed to the repo
