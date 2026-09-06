#!/bin/sh

set -eu

baseline_root=${1:-}
candidate_root=${2:-}
if [ ! -f "$baseline_root/AGENTS.md" ] || [ ! -f "$candidate_root/AGENTS.md" ]; then
  printf '%s\n' '[FAIL] usage: validate-context-refactor.sh <baseline-root> <candidate-root>' >&2
  exit 2
fi

measure_script=$candidate_root/.harness/evaluators/scripts/measure-context.py
if [ ! -f "$measure_script" ]; then
  printf '%s\n' '[FAIL] candidate context measurement script is missing' >&2
  exit 2
fi

for context_mode in global-only global-repo repo-only; do
  baseline_result=$(python3 "$measure_script" "$baseline_root" "$context_mode")
  candidate_result=$(python3 "$measure_script" "$candidate_root" "$context_mode")
  python3 -c '
import json
import sys

baseline = json.loads(sys.argv[1])
candidate = json.loads(sys.argv[2])
mode = sys.argv[3]
expected_baseline_occurrences = 2 if mode == "global-repo" else 1
if baseline["source_occurrences"] != expected_baseline_occurrences:
    raise SystemExit(f"[FAIL] {mode}: unexpected baseline source occurrences")
if candidate["source_occurrences"] != 1:
    raise SystemExit(f"[FAIL] {mode}: candidate source is missing or duplicated")
if candidate["source_ready_chars"] >= baseline["source_ready_chars"]:
    raise SystemExit(f"[FAIL] {mode}: candidate context did not decrease")
' "$baseline_result" "$candidate_result" "$context_mode"
done

printf '%s\n' '[PASS] three context discovery comparisons improved'
