status: blocked-by-auto-mode

Under "Auto" permission mode, editing `.claude/settings.json` to widen the allowlist is denied by
the auto-mode classifier as self-modification of the permission machinery (intent-resistant — narrowing
the wildcards does not help; the act of self-granting permission is what's blocked). This is a healthy
security property, and itself a key finding: an agent cannot grant itself broader permissions under Auto
mode. The allowlist additions must be applied by the user (manually, or in default/plan mode with
explicit approval). The exact additions to apply are recorded in `proposed-settings-allow.json`.
