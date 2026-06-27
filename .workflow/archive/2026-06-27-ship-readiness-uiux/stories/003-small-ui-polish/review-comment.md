<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh, cold-context 4-eye review via `/code-review` (medium effort) on the PR diff. **No blocking findings; no inline comments posted.**

### What was reviewed
- **AC3 — Settings "Idioma" chevron** (`SettingsView.swift`): the manual `HStack { Text; Spacer; Image("chevron.right") }` is replaced by a plain `Text`, so the `NavigationLink` renders exactly one disclosure chevron. The removed markup was purely redundant cosmetic styling. Correct.
- **AC4 — Map-learning back button** (`MapLearningQuizView.swift`): `navigationBarBackButtonHidden()` + a custom `chevron.backward` toolbar button calling `dismiss()`. The `showsBackButton` guard (`session?.isFinished != true`) correctly shows the button in the empty/active states and hides it only on the completion screen (which keeps its own Done-only affordance and is itself back-button-hidden). The custom control carries both `accessibilityIdentifier("BackButton")` and a localized `accessibilityLabel(a11y.back)`. Correct.
- **AC7 — Progress per-category legend** (`StatsView.swift`): new `MasteryTier.localizedName` is consumed at every production call site — header (visible short label under each icon + per-column a11y label), data cells (`"name: count"` a11y label), and the mastery-tier legend (replacing the hardcoded English `rawValue`). Correct.

### Verification performed
- **Localization completeness:** all 5 new keys (`stats.tier.name.{new,learning,review,mastered}`, `a11y.back`) are present and translated in all 21 locales — including the scaffolded ones. `just l10n-check` → PASS. The injector (`scripts/add-tier-name-strings.py`) is idempotent and stdlib-only.
- **Runtime reachability:** `MasteryTier` (`Models/MasteryTier.swift`) is the production type; `allCases`/`classify`/`icon`/`color` all exist and the new `localizedName`/`description` extensions are wired into the live `StatsView`, not just tests.
- **Cross-file / removed-behavior:** no call site broken, no invariant dropped (the removed Settings markup carried no behavior).
- **Conventions:** respects CLAUDE.md (committed script over inline one-offs; no hand-edited pbxproj).
- **AC9:** `.workflow/ui-walkthrough/scripts/003-ui-polish.json` present.

CI is green. Verdict: **APPROVED**. The formal `code-owner-review` merge-gate check is set by the separate code-owner-review agent, not here.
