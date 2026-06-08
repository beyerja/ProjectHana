#!/bin/sh
# Append an agent boundary marker to .workflow/telemetry/agents-YYYY-MM-DD.jsonl
#
# Usage:
#   agent-log.sh start <agent-name> <story-id>
#   agent-log.sh end   <agent-name> <story-id> <reads> <writes> <edits> <bashes> <est_chars> "<notes>"

set -e

ACTION="${1:?action required (start|end)}"
AGENT="${2:?agent name required}"
STORY="${3:-unknown}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$REPO_ROOT/.workflow/telemetry"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_FILE="$LOG_DIR/agents-$(date -u +%Y-%m-%d).jsonl"

if [ "$ACTION" = "start" ]; then
    printf '{"ts":"%s","event":"start","agent":"%s","story":"%s"}\n' \
        "$TIMESTAMP" "$AGENT" "$STORY" >> "$LOG_FILE"

elif [ "$ACTION" = "end" ]; then
    READS="${4:-0}"
    WRITES="${5:-0}"
    EDITS="${6:-0}"
    BASHES="${7:-0}"
    EST_CHARS="${8:-0}"
    NOTES="${9:-}"
    EST_TOKENS=$(( EST_CHARS / 4 ))
    # Look up the matching start record to compute duration
    START_TS=$(grep "\"event\":\"start\",\"agent\":\"$AGENT\",\"story\":\"$STORY\"" "$LOG_FILE" 2>/dev/null | tail -1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['ts'])" 2>/dev/null || echo "")
    if [ -n "$START_TS" ]; then
        # Compute duration in seconds via python3
        DURATION=$(python3 -c "
from datetime import datetime, timezone
start = datetime.fromisoformat('${START_TS}'.replace('Z','+00:00'))
end = datetime.fromisoformat('${TIMESTAMP}'.replace('Z','+00:00'))
print(int((end - start).total_seconds()))
" 2>/dev/null || echo "0")
    else
        DURATION=0
    fi
    # Escape notes for JSON
    NOTES_ESCAPED=$(echo "$NOTES" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null || echo "\"\"")
    printf '{"ts":"%s","event":"end","agent":"%s","story":"%s","duration_s":%s,"reads":%s,"writes":%s,"edits":%s,"bashes":%s,"est_chars":%s,"est_tokens":%s,"notes":%s}\n' \
        "$TIMESTAMP" "$AGENT" "$STORY" "$DURATION" "$READS" "$WRITES" "$EDITS" "$BASHES" "$EST_CHARS" "$EST_TOKENS" "$NOTES_ESCAPED" >> "$LOG_FILE"
else
    echo "error: unknown action '$ACTION' (expected start|end)" >&2
    exit 1
fi
