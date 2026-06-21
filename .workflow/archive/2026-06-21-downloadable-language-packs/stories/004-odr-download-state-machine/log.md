# Log — 004 — ODR download state machine + NSBundleResourceRequest provider

2026-06-20 break-tasks: DONE, 8 tasks
2026-06-20 implement-story: DONE — all 8 tasks (ResourceRequesting seam, ODR tag mapping, download state machine, holder NSLock isolation, ODRLanguagePackProvider, selection-path wiring, FakeResourceRequest tests, project regen). lint + test green. Regenerated project to pick up new test files; skipped just install (backend-only, no new UI APIs).
2026-06-20 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/126
2026-06-20 independent-review: CHANGES_REQUESTED — fractional progress never wired in production and ODR provider never set as active provider; download path is inert in the shipped app (7 inline comments)
2026-06-20 independent-review: CHANGES_REQUESTED — blocking: fractional download progress never wired (no updateProgress/loadingProgress observation, AC #2 unmet); story-003 @MainActor concern verified addressed via NSLock-guarded holder (4 inline comments + summary)
2026-06-20 implement-story (review fix #2): DONE — installed ODRLanguagePackProvider as the active provider at launch via new LanguagePackBootstrap (injectable; guarded under XCTest), added LanguagePackDownloadStore.shared for the picker, wired HanahuacApp.init, added LanguagePackBootstrapTests. lint + test + install green.
2026-06-20 independent-review: APPROVED — both blockers resolved and tested (KVO progress wiring, no retain cycle; ODR provider installed at launch); scrutiny areas a-d all clear; CI green; 1 non-blocking inline note (restored-language launch auto-download gap, story-005 territory)
2026-06-21 verify-story: DONE — all 8 acceptance criteria verified against merged feature branch (cf0d5f1). just test => TEST SUCCEEDED.
