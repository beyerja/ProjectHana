#!/bin/sh
# PostToolUse hook — appends one JSONL record per tool call to .workflow/telemetry/hooks-YYYY-MM-DD.jsonl
# Claude Code passes the tool use payload as JSON on stdin.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$REPO_ROOT/.workflow/telemetry"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="$LOG_DIR/hooks-$(date -u +%Y-%m-%d).jsonl"

# Read stdin (hook payload); if empty, write a minimal record
PAYLOAD=$(cat 2>/dev/null || true)

if [ -z "$PAYLOAD" ]; then
    echo "{\"ts\":\"$TIMESTAMP\",\"tool\":\"unknown\",\"input_chars\":0,\"output_chars\":0,\"est_tokens\":0}" >> "$LOG_FILE"
    exit 0
fi

# Extract tool_name; fall back to "unknown" if jq unavailable or field absent
TOOL=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name', d.get('tool','unknown')))" 2>/dev/null || echo "unknown")

# Estimate chars from input and output fields (may be objects or strings)
CHARS=$(echo "$PAYLOAD" | python3 -c "
import sys, json
d = json.load(sys.stdin)
def size(v):
    if isinstance(v, str): return len(v)
    if v is None: return 0
    return len(json.dumps(v))
total = size(d.get('tool_input')) + size(d.get('tool_response', d.get('tool_output')))
print(total)
" 2>/dev/null || echo "0")

EST_TOKENS=$(( CHARS / 4 ))

printf '{"ts":"%s","tool":"%s","input_chars":0,"output_chars":%s,"est_tokens":%s}\n' \
    "$TIMESTAMP" "$TOOL" "$CHARS" "$EST_TOKENS" >> "$LOG_FILE"
