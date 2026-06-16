#!/usr/bin/env python3
"""Print a summary table from agent telemetry (.workflow/telemetry/agents-*.jsonl).

By default reads only the live sink (the current workflow) — this is what Phase 1 of
evaluate-workflow uses. Pass --history (or --all) to also include the committed archived
sinks under .workflow/archive/*/telemetry/, giving the cross-run view that Phase 2b needs.
"""
import sys
import json
import collections
import glob

history = any(a in ("--history", "--all") for a in sys.argv[1:])

patterns = [".workflow/telemetry/agents-*.jsonl"]
if history:
    patterns.append(".workflow/archive/*/telemetry/agents-*.jsonl")

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

dates = sorted({r["ts"][:10] for r in ends if r.get("ts")})
scope = "live + archived" if history else "live (current workflow)"
print(f"Telemetry scope: {scope} — {len(ends)} agent runs across {len(dates)} distinct date(s).")
if history:
    print(f"Distinct workflow dates: {', '.join(dates) if dates else 'none'}")
print()

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
