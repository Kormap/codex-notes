#!/bin/sh

set -u

candidate_repo_root=${1:-}
if [ -z "$candidate_repo_root" ] || [ ! -d "$candidate_repo_root/.harness" ]; then
  printf '%s\n' '[FAIL] usage: validate-report-sources.sh <repository-root>' >&2
  exit 2
fi

candidate_diagnostics=$(mktemp "${TMPDIR:-/tmp}/report-source-candidate.XXXXXX") || exit 1
trap 'rm -f "$candidate_diagnostics"' EXIT HUP INT TERM

candidate_field_value() {
  awk -v target="$2" '
    {
      prefix = "- `" target "`: `"
      if (index($0, prefix) == 1 && substr($0, length($0), 1) == "`") {
        print substr($0, length(prefix) + 1, length($0) - length(prefix) - 1)
      }
    }
  ' "$1"
}

candidate_errors=0

for candidate_report_file in "$candidate_repo_root"/.harness/reports/*.md; do
  [ -f "$candidate_report_file" ] || continue
  [ "$(basename -- "$candidate_report_file")" = 'README.md' ] && continue

  awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function bare(value) {
      value = trim(value)
      if (value ~ /^`[^`]+`$/) return substr(value, 2, length(value) - 2)
      return value
    }
    /^## / {
      in_sources = ($0 == "## Source Trace (`source_traces`)")
      next
    }
    in_sources && /^\|/ {
      column_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /trace_id/ || first ~ /^-+$/ || column_count != 12) next
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
        bare(column[2]), bare(column[3]), bare(column[4]), bare(column[5]), \
        bare(column[6]), bare(column[7]), bare(column[8]), bare(column[9]), bare(column[10])
    }
  ' "$candidate_report_file" > "$candidate_diagnostics"

  while IFS='	' read -r candidate_trace_id candidate_recorded_at candidate_task_type candidate_trace_level candidate_final_result candidate_attempt_count candidate_rework_count candidate_has_unverified candidate_has_risk; do
    [ -n "$candidate_trace_id" ] || continue
    candidate_trace_file="$candidate_repo_root/.harness/traces/runs/$candidate_trace_id.md"
    if [ ! -f "$candidate_trace_file" ]; then
      printf '[FAIL] %s: source trace is missing: %s\n' "${candidate_report_file#"$candidate_repo_root"/}" "$candidate_trace_id" >&2
      candidate_errors=$((candidate_errors + 1))
      continue
    fi

    candidate_actual_unverified=true
    [ "$(candidate_field_value "$candidate_trace_file" unverified)" = 'NONE' ] && candidate_actual_unverified=false
    candidate_actual_risk=true
    [ "$(candidate_field_value "$candidate_trace_file" remaining_risks)" = 'NONE' ] && candidate_actual_risk=false

    for candidate_field in recorded_at task_type trace_level final_result attempt_count rework_count; do
      case "$candidate_field" in
        recorded_at) candidate_report_value=$candidate_recorded_at ;;
        task_type) candidate_report_value=$candidate_task_type ;;
        trace_level) candidate_report_value=$candidate_trace_level ;;
        final_result) candidate_report_value=$candidate_final_result ;;
        attempt_count) candidate_report_value=$candidate_attempt_count ;;
        rework_count) candidate_report_value=$candidate_rework_count ;;
      esac
      candidate_trace_value=$(candidate_field_value "$candidate_trace_file" "$candidate_field")
      if [ "$candidate_report_value" != "$candidate_trace_value" ]; then
        printf '[FAIL] %s: source trace %s %s differs from trace: report=%s trace=%s\n' \
          "${candidate_report_file#"$candidate_repo_root"/}" "$candidate_trace_id" "$candidate_field" "$candidate_report_value" "$candidate_trace_value" >&2
        candidate_errors=$((candidate_errors + 1))
      fi
    done

    if [ "$candidate_has_unverified" != "$candidate_actual_unverified" ]; then
      printf '[FAIL] %s: source trace %s has_unverified differs from trace\n' "${candidate_report_file#"$candidate_repo_root"/}" "$candidate_trace_id" >&2
      candidate_errors=$((candidate_errors + 1))
    fi
    if [ "$candidate_has_risk" != "$candidate_actual_risk" ]; then
      printf '[FAIL] %s: source trace %s has_remaining_risk differs from trace\n' "${candidate_report_file#"$candidate_repo_root"/}" "$candidate_trace_id" >&2
      candidate_errors=$((candidate_errors + 1))
    fi
  done < "$candidate_diagnostics"
done

if [ "$candidate_errors" -ne 0 ]; then
  printf '[Summary] report source candidate errors=%s\n' "$candidate_errors" >&2
  exit 1
fi

printf '%s\n' '[PASS] report source rows match referenced traces'
