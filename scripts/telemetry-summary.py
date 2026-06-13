#!/usr/bin/env python3
"""Print a summary table from .workflow/telemetry/agents-*.jsonl files."""
import sys
import json
import collections
import glob

patterns = [".workflow/telemetry/agents-*.jsonl"]
files = []
for p in patterns:
    files.extend(sorted(glob.glob(p)))

if not files:
    print("No telemetry found.")
    sys.exit(0)

ends = []
for path in files:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if r.get("event") == "end":
                ends.append(r)

if not ends:
    print("No completed agent records found.")
    sys.exit(0)

agents = collections.defaultdict(lambda: {"runs": 0, "dur_sum": 0.0, "tok_sum": 0.0, "retries": 0})
for r in ends:
    a = r.get("agent", "unknown")
    agents[a]["runs"] += 1
    agents[a]["dur_sum"] += r.get("duration_s", 0)
    agents[a]["tok_sum"] += r.get("est_tokens", 0)
    if r.get("notes"):
        agents[a]["retries"] += 1

print(f"| {'Agent':<26} | {'Runs':>4} | {'Avg Duration':>12} | {'Avg Est Tokens':>14} | {'Total Retries/Notes':>19} |")
print(f"|{'-'*28}|{'-'*6}|{'-'*14}|{'-'*16}|{'-'*21}|")
for name, d in sorted(agents.items()):
    avg_min = (d["dur_sum"] / d["runs"] / 60) if d["runs"] else 0
    avg_tok = (d["tok_sum"] / d["runs"]) if d["runs"] else 0
    print(f"| {name:<26} | {d['runs']:>4} | {avg_min:>11.1f}m | {avg_tok:>14.0f} | {d['retries']:>19} |")
