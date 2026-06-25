**Step-index off-by-one for steps 013–016 (documentation, non-blocking).**

The driver emits step `000` (initial) then one artifact per action, so script action *N* (0-indexed) maps to artifact `00(N+1)`. The settings tap is `script[13]` (`tap home.settings`) → artifact **014**, and the preceding `wait 2s` is `script[12]` → artifact **013**.

So this row is inaccurate: artifact `013-step.png` actually still shows **Home** (it is byte-identical to `000-step.png`), not Settings. Settings first appears in `014-step.png`. The footnote below ("Step 013 is the artifact captured immediately after the `tap` identifier `home.settings` step") is also off-by-one — `home.settings` produces artifact 014, not 013.

Suggest shifting the 012→016 rows down by one so each artifact maps to the action that produced it (012 = `tap Salir` → Home; 013 = `wait 2s` → Home; 014 = `tap home.settings` → Settings; 015 = `wait 2s` → Settings; 016 = `screenshot` → Settings). The evidence itself is correct and the path is genuinely demonstrated — only the table labels are wrong.
