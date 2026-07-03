# Log — Localize the Multiple-Choice quiz prompt + country/feature names (AC1)

2026-06-26 break-tasks: DONE, 10 tasks

2026-06-26 implement-story: AUDIT (task 001) — Confirmed in MultipleChoiceSession.swift:
- countryCapitalQuestions: prompt via L10n("quiz.prompt.capital_of") + localizedName/localizedCapital — localized.
- continentQuestions: prompt via L10n("quiz.prompt.continent_of"), continent options via localizedContinent, feature name via factLocalizedName — localized WHEN the caller passes locale + factLocalizedName.
- seaIdentificationQuestions: prompt was hardcoded English "Which body of water is located at approximately <region>?" with English approximateRegion (N/S/E/W) — THE LEAK. Sea NAME options already used localizedName.
Ruled out other theories for the user-reported "What is the capital of Ukraine?" leak: it is NOT a missing es-MX quiz.prompt key (present), NOT a GeoNameResolver miss (localizedName works). The real residual leak was a SECOND MC entry point.

2026-06-26 implement-story: ROOT-CAUSE CONFIRMED VIA WALKTHROUGH — The live ui-walkthrough (run story001-mc-v2, step 018) with the app set to Spanish showed the new-card MC prompt STILL English: "What is the capital of Ukraine?" while the chrome was Spanish ("Salir"/"Aprender"/"graduadas"). Traced to LearningQuizView.makeQuestion (the "Aprender"/new-card MC flow), which called the factory methods WITHOUT a locale arg (defaulting to .en) and without factLocalizedName. The review MC path (MultipleChoiceQuizView.buildSession) already passed locale correctly. Fixed makeQuestion to pass LanguageManager.shared.current + factLocalizedName for rivers/mountains, matching the review path.

2026-06-26 implement-story: CHANGES —
- Sea prompt routed through L10n("quiz.prompt.sea_location") + locale-aware approximateRegion using quiz.region.{north,south,east,west}.
- New keys added to all 13 fully/partly-translated locales (nah falls back by design): quiz.prompt.sea_location + 4 quiz.region.* cardinal letters.
- IDENTICAL_VALUE_ALLOWLIST extended for legitimately-shared single-letter compass abbreviations (N/S/E/W per language).
- LearningQuizView.makeQuestion now passes the active locale.
- Tests: extended LocalizedQuizPromptTests with Spanish (full-pipeline) + English sea-prompt tests and a German shipped-pack (ODR) test for the sea template + region label.
- Walkthrough script authored: .workflow/ui-walkthrough/scripts/001-localize-mc.json.
just lint: PASS (l10n-check PASS, 0 warnings). just test: TEST SUCCEEDED.
Skipped just generate/just install: no new compiled source/resource files added (modified existing Swift + .lproj strings + .workflow json only).

2026-06-26 implement-story: DONE — all 10 tasks (sea prompt localized, new keys in all locales, LearningQuizView locale leak fixed, tests + walkthrough script added), lint + test green. Commit 0b80695 on story/ship-readiness-uiux/001-localize-multiple-choice.

2026-06-26 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/183

2026-06-26 18:44 independent-review: APPROVED — AC1 locale threaded into both MC entry points (review + new-card); just l10n-check PASS; no blocking findings, 3 non-blocking nits posted inline.

2026-06-26 code-owner-review: APPROVED — independent confirm; AC1 locale threaded through both MC entry points (new-card makeQuestion fix), l10n-check PASS (161 keys), CI green on f3b44f8; code-owner-review check=success posted+read-back (app 4144849).

2026-06-26 merge-pr: DONE — squash-merged PR 183 into main, story branch deleted. Merge commit 75775d3b60480d4164b20d09e3d7f20b6f5b9c72.
