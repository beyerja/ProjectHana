#!/bin/sh
# PreToolUse hook — captures Bash commands that would trigger a permission prompt.
#
# For each PreToolUse event, read the tool + command from the JSON payload on stdin.
# A command is "would-prompt" when it is NOT matched by the effective allowlist, which
# is the union of permissions.allow from .claude/settings.json and
# .claude/settings.local.json. Unmatched commands are appended as one JSON line to
# .workflow/telemetry/permissions-<date>.jsonl. Matched commands are ignored.
#
# This hook MUST fail open: any error (missing file, bad payload, parse failure) exits 0
# and never blocks or errors the tool call. It is dependency-light (sh + python3, the same
# baseline as the existing PostToolUse telemetry hook) and runs on every tool call.

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || exit 0
REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)" || exit 0

# Read the hook payload from stdin (best effort).
PAYLOAD=$(cat 2>/dev/null || true)

# All real work happens in python3 for robust JSON + glob handling. The payload is passed
# via an environment variable (the heredoc below occupies python's stdin). If python3 is
# unavailable or anything throws, we swallow it and exit 0 (fail open).
HOOK_PAYLOAD="$PAYLOAD" HOOK_REPO_ROOT="$REPO_ROOT" python3 - 2>/dev/null <<'PY' || true
import sys, os, json, fnmatch, datetime

def main():
    repo_root = os.environ.get("HOOK_REPO_ROOT", ".")

    raw = os.environ.get("HOOK_PAYLOAD", "")
    if not raw.strip():
        return  # empty payload -> nothing to record, fail open

    try:
        payload = json.loads(raw)
    except Exception:
        return  # malformed payload -> fail open

    tool = payload.get("tool_name", payload.get("tool", "")) or ""
    tool_input = payload.get("tool_input", {}) or {}
    command = ""
    if isinstance(tool_input, dict):
        command = tool_input.get("command", "") or ""

    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    log_dir = os.path.join(repo_root, ".workflow", "telemetry")
    log_file = os.path.join(
        log_dir,
        "permissions-" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d") + ".jsonl",
    )

    # Non-Bash tools: record only the tool name field (command matching is out of scope).
    if tool != "Bash":
        record = {"ts": ts, "tool": tool}
        write_record(log_dir, log_file, record)
        return

    if not command:
        return  # nothing to evaluate

    allow = load_allowlist(repo_root)
    if command_is_allowed(command, allow):
        return  # already covered -> no record (no false positive)

    record = {
        "ts": ts,
        "tool": tool,
        "command": command,
        "signature": signature(command),
    }
    write_record(log_dir, log_file, record)


def load_allowlist(repo_root):
    """Union of permissions.allow Bash(...) patterns from both settings files."""
    patterns = []
    for name in ("settings.json", "settings.local.json"):
        path = os.path.join(repo_root, ".claude", name)
        try:
            with open(path, "r") as fh:
                data = json.load(fh)
        except Exception:
            continue  # missing/optional .local file or bad JSON -> skip gracefully
        for entry in (data.get("permissions", {}) or {}).get("allow", []) or []:
            if isinstance(entry, str) and entry.startswith("Bash(") and entry.endswith(")"):
                patterns.append(entry[len("Bash("):-1])
    return patterns


def command_is_allowed(command, patterns):
    """A pattern matches if the command equals it, or (when the pattern ends in '*')
    the command starts with the literal prefix before the trailing '*'. We also support
    interior '*' via fnmatch for patterns like 'DEVELOPER_DIR=* xcodebuild *'."""
    cmd = command.strip()
    for pat in patterns:
        p = pat.strip()
        if not p:
            continue
        if "*" not in p:
            if cmd == p:
                return True
            continue
        # Fast path: a single trailing wildcard is a prefix match.
        if p.endswith("*") and "*" not in p[:-1]:
            if cmd.startswith(p[:-1]):
                return True
            continue
        # General case (interior wildcards, e.g. "DEVELOPER_DIR=* xcodebuild *"):
        # treat the pattern as a glob over the whole command. A trailing '*' already
        # lets the match consume "anything after", matching Claude's prefix semantics.
        if fnmatch.fnmatch(cmd, p):
            return True
    return False


def signature(command):
    """Normalized signature: leading executable + first subcommand, so repeats group.
    Strips a leading 'VAR=val ' assignment prefix and ignores options."""
    toks = command.strip().split()
    # Drop leading env-var assignments (e.g. DEVELOPER_DIR=...).
    i = 0
    while i < len(toks) and "=" in toks[i] and not toks[i].startswith("-") and "/" not in toks[i].split("=")[0]:
        i += 1
    rest = toks[i:]
    if not rest:
        return command.strip()
    exe = os.path.basename(rest[0])
    sub = ""
    for t in rest[1:]:
        if t.startswith("-"):
            continue
        sub = t
        break
    return (exe + " " + sub).strip() if sub else exe


def write_record(log_dir, log_file, record):
    try:
        os.makedirs(log_dir, exist_ok=True)
        with open(log_file, "a") as fh:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception:
        return  # writing must never fail the tool call


try:
    main()
except Exception:
    pass  # fail open under all circumstances
PY

exit 0
