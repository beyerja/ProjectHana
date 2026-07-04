## Tasks
- [x] 001: Add `"mac"` idiom image entry to `/Users/Private/Documents/Code/ProjectHana-worktrees/mac-catalyst-app-icon/Hanahuac/Assets.xcassets/AppIcon.appiconset/Contents.json` alongside the existing `"universal"` entry, referencing `AppIcon.png` at `1024x1024` scale `1x`
- [x] 002: Verify with `just build-mac` that the Mac Catalyst bundle contains `AppIcon.icns` under `Contents/Resources/`, then run `just test` and `just lint` to confirm no regressions
