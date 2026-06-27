<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of the AC8 Type-Capital input layout change (2 files, +30/-7).

**Verdict: APPROVED** — no blocking findings.

### What was verified
- **Layout change is sound.** `quizBody` now keeps progress + prompt in a `ScrollView` with `.scrollDismissesKeyboard(.interactively)` and pins `answerSection` to the bottom via `.safeAreaInset(edge: .bottom)` with `.padding().background(.bar)`. This is the canonical SwiftUI pattern for an action bar above the keyboard; keyboard avoidance lifts the bottom inset with the keyboard so the field and the Verificar/Siguiente button stay visible and usable (AC1, AC2).
- **Runtime reachability.** `quizBody` is the sole render path and is called from both production branches — `pendingContent` (due cards) and `newContent` (learning). The fix is on the live path, not gated behind tests.
- **Accessibility ids preserved.** `quiz.input` (line 224) and `quiz.submit` (line 237) unchanged on the field and submit button.
- **Feedback / "Siguiente" state intact.** The `.correct`/`.incorrect` branches of `answerSection` still render through the same switch, now inside the bottom inset — no regression to that path.
- **No new unlocalized strings.** The diff moves existing code only; it adds zero new `L10n[...]` keys.
- **Driver script valid (AC9).** `005-type-capital-layout.json` conforms to the documented schema (`dumpTree`/`screenshot`/`tap`/`wait`/`typeText` with valid fields), and `home.mode.typeCapital` resolves to a real element (`home.mode.\(quizModeRawValue)` where `QuizModeID.typeCapital.rawValue == "typeCapital"`).

### Non-blocking notes (posted inline)
- The sibling `NameFeatureQuizView` has the same `TextField` + button pattern in a plain bottom `VStack` and likely the same keyboard-obscuring bug — out of scope for AC8 (Type-Capital only), worth a follow-up story. A shared input view would let one fix cover both.
- Cross-question auto-focus now relies on `.onAppear { fieldFocused = true }` firing for the `.unanswered` branch inside the bottom inset (the same switch-driven re-present the unchanged sibling already depends on). Worth confirming in the live AC9 before/after dumps that the field re-focuses after tapping Siguiente, not just on first entry.

Refuted as introduced bugs: double safe-area padding, removed `Spacer(minLength:)`, and interactive-dismiss flicker — all either inert in a ScrollView or the intended behavior of the API.

The formal `code-owner-review` merge gate is set by the separate code-owner-review step, not here.
