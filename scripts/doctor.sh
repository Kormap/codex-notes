#!/bin/sh

set -u

if [ -z "${HOME:-}" ]; then
  printf '%s\n' '[FAIL] HOME must be set to inspect installed skills' >&2
  exit 1
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
user_skills_dir=${HOME}/.agents/skills
system_skills_dir=${HOME}/.codex/skills/.system
error_count=0
warning_count=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  error_count=$((error_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1" >&2
  warning_count=$((warning_count + 1))
}

make_temp() {
  mktemp "${TMPDIR:-/tmp}/codex-notes-doctor.XXXXXX"
}

field_value() {
  awk -v target="$2" '
    {
      prefix = "- `" target "`: `"
      if (index($0, prefix) == 1 && substr($0, length($0), 1) == "`") {
        print substr($0, length(prefix) + 1, length($0) - length(prefix) - 1)
      }
    }
  ' "$1"
}

field_count() {
  awk -v target="$2" '
    {
      prefix = "- `" target "`: `"
      if (index($0, prefix) == 1 && substr($0, length($0), 1) == "`") {
        count++
      }
    }
    END { print count + 0 }
  ' "$1"
}

require_scalar_field() {
  scalar_file=$1
  scalar_key=$2
  scalar_relative=${scalar_file#"$repo_root"/}
  scalar_count=$(field_count "$scalar_file" "$scalar_key")
  if [ "$scalar_count" -ne 1 ]; then
    fail "$scalar_relative: $scalar_key must appear exactly once"
    return 1
  fi

  scalar_value=$(field_value "$scalar_file" "$scalar_key")
  if [ -z "$scalar_value" ]; then
    fail "$scalar_relative: $scalar_key must not be empty"
    return 1
  fi
}

require_heading() {
  heading_file=$1
  heading=$2
  heading_relative=${heading_file#"$repo_root"/}
  if ! grep -Fqx "$heading" "$heading_file"; then
    fail "$heading_relative: required heading is missing: $heading"
  fi
}

require_exact_line() {
  exact_file=$1
  exact_line=$2
  exact_description=$3
  exact_relative=${exact_file#"$repo_root"/}
  if ! grep -Fqx -- "$exact_line" "$exact_file"; then
    fail "$exact_relative: $exact_description"
  fi
}

require_index_link() {
  index_file=$1
  index_target=$2
  index_description=$3
  index_relative=${index_file#"$repo_root"/}
  if ! grep -Fq "]($index_target)" "$index_file"; then
    fail "$index_relative: missing index link for $index_description: $index_target"
  fi
}

valid_kebab_id() {
  case "$1" in
    ''|-*|*-|*--*|*[!a-z0-9-]*) return 1 ;;
    *) return 0 ;;
  esac
}

validate_known_baseline_version() {
  version_file=$1
  version_label=$2
  version_value=$(field_value "$version_file" baseline_version)

  if ! printf '%s\n' "$version_value" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$version_label: invalid baseline_version: $version_value"
  elif ! grep -Fq "| \`$version_value\` |" "$repo_root/.harness/baseline/version.md"; then
    fail "$version_label: unknown baseline_version: $version_value"
  fi
}

validate_baseline_history() {
  baseline_file=$1

  if ! awk '
    function trim(value) { sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); return value }
    function bare(value) { value = trim(value); if (value ~ /^`[^`]+`$/) return substr(value, 2, length(value) - 2); return value }
    /^- Version: `/ { current_version_count++; current_version = $0; sub(/^- Version: `/, "", current_version); sub(/`$/, "", current_version) }
    /^- Status: / { current_status_count++; current_status = $0; sub(/^- Status: /, "", current_status) }
    /^- Effective date \(Asia\/Seoul\): / { current_date_count++; current_date = $0; sub(/^- Effective date \(Asia\/Seoul\): /, "", current_date) }
    /^- Approved by: / { approver_count++; approver = $0; sub(/^- Approved by: /, "", approver) }
    $0 == "## 변경 이력" { in_history = 1; next }
    in_history && /^\|/ {
      column_count = split($0, column, "|")
      version = bare(column[2])
      if (version == "버전" || version ~ /^-+$/) next
      row_count++
      if (column_count != 6) { print "version history row " row_count " must have four columns"; next }
      date = trim(column[3])
      status = trim(column[4])
      summary = trim(column[5])
      if (version !~ /^[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$/) print "version history row " row_count " has invalid version: " version
      else if (seen_version[version]++) print "duplicate baseline version: " version
      if (date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) print "version history row " row_count " has invalid effective date: " date
      if (status != "초기 적용" && status != "이전" && status != "활성") print "version history row " row_count " has invalid status: " status
      if (summary == "") print "version history row " row_count " has empty change summary"
      history_date[version] = date
      history_status[version] = status
      if (status == "활성") active_count++
    }
    END {
      if (current_version_count != 1) print "Version must appear exactly once"
      if (current_status_count != 1 || current_status != "활성") print "current Status must appear exactly once and be 활성"
      if (current_date_count != 1 || current_date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) print "Effective date must appear exactly once in YYYY-MM-DD format"
      if (approver_count != 1 || approver == "") print "Approved by must appear exactly once and not be empty"
      if (row_count == 0) print "no baseline version history rows found"
      if (active_count != 1) print "version history must contain exactly one 활성 row"
      if (!(current_version in history_status)) print "current Version is missing from version history: " current_version
      else {
        if (history_status[current_version] != "활성") print "current Version history row must be 활성: " current_version
        if (history_date[current_version] != current_date) print "current Version effective date differs from history: " current_version
      }
    }
  ' "$baseline_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse baseline version history' > "$harness_diagnostics"
  fi
}

validate_task_acceptance() {
  acceptance_task_file=$1

  if ! awk '
    $0 == "## 성공 조건 (`acceptance_criteria`)" {
      in_acceptance = 1
      next
    }
    in_acceptance && /^## / {
      in_acceptance = 0
    }
    in_acceptance && /^- \[/ {
      if ($0 !~ /^- \[[ xX]\] `AC-[A-Z0-9-]+-[0-9][0-9]`:/) {
        print "invalid acceptance criterion row: " $0
        next
      }
      match($0, /`AC-[A-Z0-9-]+-[0-9][0-9]`/)
      acceptance_id = substr($0, RSTART + 1, RLENGTH - 2)
      acceptance_count++
      if (seen_acceptance[acceptance_id]++) {
        print "duplicate acceptance criterion: " acceptance_id
      }
    }
    END {
      if (acceptance_count == 0) {
        print "no acceptance criteria found"
      }
    }
  ' "$acceptance_task_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse acceptance criteria' > "$harness_diagnostics"
  fi
}

validate_evaluator_mapping() {
  mapping_evaluator_file=$1
  mapping_task_file=$2

  if ! awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    FNR == NR {
      if ($0 == "## 성공 조건 (`acceptance_criteria`)") {
        in_task_acceptance = 1
        next
      }
      if (in_task_acceptance && /^## /) {
        in_task_acceptance = 0
      }
      if (in_task_acceptance && $0 ~ /^- \[[ xX]\] `AC-[A-Z0-9-]+-[0-9][0-9]`:/) {
        match($0, /`AC-[A-Z0-9-]+-[0-9][0-9]`/)
        task_acceptance[substr($0, RSTART + 1, RLENGTH - 2)] = 1
      }
      next
    }
    $0 == "## 검사 (`evaluation_checks`)" {
      in_mapping = 1
      next
    }
    in_mapping && /^## / {
      in_mapping = 0
    }
    !in_mapping || $0 !~ /^\|/ {
      next
    }
    {
      column_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /check_id/ || first ~ /^-+$/) {
        next
      }
      row_count++
      if (column_count != 6) {
        print "evaluation mapping row " row_count " must have four columns"
        next
      }

      check_id = trim(column[2])
      acceptance_cell = trim(column[3])
      requirement = trim(column[4])
      method = trim(column[5])

      if (check_id !~ /^`EV-[A-Z0-9-]+-[0-9][0-9]`$/) {
        print "evaluation mapping row " row_count " has invalid check_id: " check_id
      } else {
        bare_check_id = substr(check_id, 2, length(check_id) - 2)
        if (seen_check[bare_check_id]++) {
          print "duplicate evaluation check_id: " bare_check_id
        }
      }
      if (requirement != "`REQUIRED`" && requirement != "`CONDITIONAL`") {
        print "evaluation mapping row " row_count " has invalid requirement: " requirement
      }
      if (method == "" || method ~ /<[^>]+>/) {
        print "evaluation mapping row " row_count " has empty or placeholder method"
      }

      acceptance_count = split(acceptance_cell, acceptance, ",")
      for (item_index = 1; item_index <= acceptance_count; item_index++) {
        acceptance_id = trim(acceptance[item_index])
        if (acceptance_id !~ /^`AC-[A-Z0-9-]+-[0-9][0-9]`$/) {
          print "evaluation mapping row " row_count " has invalid acceptance criterion: " acceptance_id
          continue
        }
        acceptance_id = substr(acceptance_id, 2, length(acceptance_id) - 2)
        if (!(acceptance_id in task_acceptance)) {
          print "evaluation mapping row " row_count " references unknown acceptance criterion: " acceptance_id
        } else {
          connected_acceptance[acceptance_id] = 1
        }
      }
    }
    END {
      if (row_count == 0) {
        print "no evaluation check mapping rows found"
      }
      for (acceptance_id in task_acceptance) {
        if (!(acceptance_id in connected_acceptance)) {
          print "acceptance criterion is not connected from evaluation mapping: " acceptance_id
        }
      }
    }
  ' "$mapping_task_file" "$mapping_evaluator_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse evaluation mapping' > "$harness_diagnostics"
  fi
}

validate_trace_results() {
  result_trace_file=$1
  result_trace_final=$2

  if ! awk -v final_result="$result_trace_final" '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    $0 == "## 성공 조건 (`success_criteria`)" {
      in_success = 1
      next
    }
    in_success && /^## / {
      in_success = 0
    }
    in_success && /^- \[/ {
      if ($0 !~ /^- \[[ xX]\] `SC-[0-9][0-9]`:/) {
        print "invalid success criterion row: " $0
        next
      }
      match($0, /`SC-[0-9][0-9]`/)
      success_id = substr($0, RSTART + 1, RLENGTH - 2)
      success_count++
      if (seen_success[success_id]++) {
        print "duplicate success criterion: " success_id
      }
      if ($0 ~ /^- \[ \]/) {
        incomplete_success = 1
      }
    }
    $0 == "## 검증 결과 (`evaluator_results`)" {
      in_results = 1
      next
    }
    in_results && /^## / {
      in_results = 0
    }
    !in_results || $0 !~ /^\|/ {
      next
    }
    {
      column_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /evaluator_id/ || first ~ /^-+$/) {
        next
      }
      result_count++
      if (column_count != 6) {
        print "evaluator result row " result_count " must have four columns"
        next
      }
      result = trim(column[4])
      if (result == "`FAIL`") {
        has_fail = 1
      } else if (result == "`BLOCKED`") {
        has_blocked = 1
      } else if (result != "`PASS`") {
        print "evaluator result row " result_count " has invalid result: " result
        invalid_result = 1
      }
    }
    END {
      if (success_count == 0) {
        print "no success criteria found"
      }
      if (result_count == 0) {
        print "no evaluator result rows found"
      }
      if (has_fail || incomplete_success) {
        expected = "FAIL"
      } else if (has_blocked) {
        expected = "BLOCKED"
      } else {
        expected = "PASS"
      }
      if (!invalid_result && final_result != expected) {
        print "final_result " final_result " contradicts evaluator results and success criteria; expected " expected
      }
    }
  ' "$result_trace_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse trace results' > "$harness_diagnostics"
  fi
}

check_extended_scalar_group() {
  group_trace_file=$1
  group_trigger=$2
  shift 2
  group_relative=${group_trace_file#"$repo_root"/}

  for group_key in "$@"; do
    group_value=$(field_value "$group_trace_file" "$group_key")
    case "$group_trigger" in
      false)
        [ "$group_value" = 'NOT_APPLICABLE' ] || \
          fail "$group_relative: $group_key must be NOT_APPLICABLE when its trigger is false"
        ;;
      true)
        case "$group_value" in
          NOT_APPLICABLE|*'<'*'>'*)
            fail "$group_relative: $group_key must contain applicable, resolved evidence when its trigger is true"
            ;;
        esac
        ;;
    esac
  done
}

validate_extended_tables() {
  table_trace_file=$1
  table_high_risk=$2
  table_repeated=$3
  table_multi_agent=$4

  if ! awk \
    -v high_risk="$table_high_risk" \
    -v repeated="$table_repeated" \
    -v multi_agent="$table_multi_agent" '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function bare(value) {
      value = trim(value)
      if (value ~ /^`[^`]+`$/) {
        return substr(value, 2, length(value) - 2)
      }
      return value
    }
    function table_name(key) {
      if (key == "risks") return "risks"
      if (key == "approvals") return "approvals"
      if (key == "comparison") return "comparison_results"
      if (key == "assignments") return "agent_assignments"
      return "delegations"
    }
    function expected_columns(key) {
      if (key == "risks") return 4
      return 5
    }
    function trigger_for(key) {
      if (key == "risks" || key == "approvals") return high_risk
      if (key == "comparison") return repeated
      return multi_agent
    }
    function validate_row(key, column, split_count, data_columns, trigger, cell_index, value, decision, performed) {
      data_columns = expected_columns(key)
      trigger = trigger_for(key)
      if (split_count != data_columns + 2) {
        print table_name(key) " row " row_count[key] " must have " data_columns " columns"
        return
      }
      for (cell_index = 2; cell_index <= data_columns + 1; cell_index++) {
        value = trim(column[cell_index])
        if (trigger == "false" && value != "`NOT_APPLICABLE`") {
          print table_name(key) " false-trigger row must contain only NOT_APPLICABLE"
          break
        }
        if (trigger == "true" && (value == "" || value == "`NOT_APPLICABLE`" || value ~ /<[^>]+>/)) {
          print table_name(key) " true-trigger row must contain applicable, resolved evidence"
          break
        }
      }
      if (trigger != "true") return

      if (key == "approvals") {
        decision = bare(column[4])
        performed = bare(column[5])
        if (decision != "APPROVED" && decision != "DENIED" && decision != "PENDING") {
          print "approvals row " row_count[key] " has invalid decision: " decision
        }
        if (performed != "true" && performed != "false") {
          print "approvals row " row_count[key] " has invalid performed value: " performed
        }
        if ((decision == "DENIED" || decision == "PENDING") && performed != "false") {
          print "approvals row " row_count[key] " requires performed=false for " decision
        }
        if (performed == "true" && decision != "APPROVED") {
          print "approvals row " row_count[key] " requires APPROVED when performed=true"
        }
      } else if (key == "comparison") {
        previous = bare(column[3])
        current = bare(column[4])
        quality = bare(column[5])
        if (previous != "PASS" && previous != "FAIL" && previous != "BLOCKED") {
          print "comparison_results row " row_count[key] " has invalid previous_result: " previous
        }
        if (current != "PASS" && current != "FAIL" && current != "BLOCKED") {
          print "comparison_results row " row_count[key] " has invalid current_result: " current
        }
        if (quality != "IMPROVED" && quality != "UNCHANGED" && quality != "DEGRADED") {
          print "comparison_results row " row_count[key] " has invalid quality_change: " quality
        }
      } else if (key == "assignments") {
        role = bare(column[3])
        status = bare(column[6])
        if (role != "Lead" && role != "Researcher" && role != "Implementer" && role != "Reviewer" && role != "Verifier") {
          print "agent_assignments row " row_count[key] " has invalid role: " role
        }
        if (status != "COMPLETED" && status != "NEEDS_LEAD_DECISION" && status != "NEEDS_USER_APPROVAL" && status != "BLOCKED") {
          print "agent_assignments row " row_count[key] " has invalid status: " status
        }
      } else if (key == "delegations") {
        adopted = bare(column[5])
        if (adopted != "ADOPTED" && adopted != "REJECTED" && adopted != "PARTIAL") {
          print "delegations row " row_count[key] " has invalid result_adopted: " adopted
        }
      }
    }
    function select_table(line) {
      if (line == "### 위험 (`risks`)") return "risks"
      if (line == "### 승인 (`approvals`)") return "approvals"
      if (line == "### 비교 결과 (`comparison_results`)") return "comparison"
      if (line == "### 역할 배정과 소유권 (`agent_assignments`)") return "assignments"
      if (line == "### 위임과 역할 결과 (`delegations`)") return "delegations"
      return ""
    }
    /^#{1,3} / {
      selected = select_table($0)
      current_table = selected
      next
    }
    current_table == "" || $0 !~ /^\|/ {
      next
    }
    {
      split_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /^-+$/ || first ~ /\(`[^`]+`\)/) {
        next
      }
      row_count[current_table]++
      validate_row(current_table, column, split_count)
    }
    END {
      table_keys[1] = "risks"
      table_keys[2] = "approvals"
      table_keys[3] = "comparison"
      table_keys[4] = "assignments"
      table_keys[5] = "delegations"
      for (table_index = 1; table_index <= 5; table_index++) {
        key = table_keys[table_index]
        trigger = trigger_for(key)
        if (trigger == "false" && row_count[key] != 1) {
          print table_name(key) " must contain exactly one data row when its trigger is false"
        } else if (trigger == "true" && row_count[key] < 1) {
          print table_name(key) " must contain at least one data row when its trigger is true"
        }
      }
    }
  ' "$table_trace_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse extended trace tables' > "$harness_diagnostics"
  fi
}

validate_trace_template() {
  template_file=$1
  template_kind=$2

  require_exact_line "$template_file" \
    '- `recorded_at`: `YYYY-MM-DDThh:mm:ss+09:00`' \
    'recorded_at template must use the +09:00 timezone offset'
  require_exact_line "$template_file" \
    '| 평가자 (`evaluator_id`) | 명령 또는 방법 (`command_or_method`) | 결과 (`result`) | 근거 요약 (`evidence_summary`) |' \
    'evaluator_results header does not match the trace contract'
  require_exact_line "$template_file" \
    '|---|---|---|---|' \
    'evaluator_results separator does not match the trace contract'
  require_exact_line "$template_file" \
    '| `<식별자>` | `<재실행 가능한 명령 또는 검토 방법>` | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `<종료 코드와 핵심 결과>` |' \
    'evaluator_results placeholder row does not match the trace contract'

  [ "$template_kind" = 'extended' ] || return

  require_exact_line "$template_file" \
    '| 위험 (`risk`) | 영향 (`impact`) | 통제 (`control`) | 잔여 위험 (`residual_risk`) |' \
    'risks header does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| `<위험 항목>` | `<영향>` | `<적용한 통제>` | `<남은 위험>` |' \
    'risks placeholder row does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| 요청 시각 (`requested_at`) | 행동과 정확한 대상 (`action_target`) | 결정 (`decision`) | 수행 (`performed`) | 근거 요약 (`evidence_summary`) |' \
    'approvals header does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| `<ISO 8601>` | `<민감정보 없는 승인 대상>` | `APPROVED`, `DENIED`, `PENDING` 중 하나 | `true`, `false` 중 하나 | `<결정과 실제 수행 결과>` |' \
    'approvals placeholder row does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| 평가자 (`evaluator_id`) | 이전 결과 (`previous_result`) | 현재 결과 (`current_result`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |' \
    'comparison_results header does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| `<동일 evaluator 식별자>` | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `IMPROVED`, `UNCHANGED`, `DEGRADED` 중 하나 | `<차이와 원인>` |' \
    'comparison_results placeholder row does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| 에이전트·작업 ID (`agent_task_id`) | 역할 (`role`) | 배정 범위 (`assigned_scope`) | 쓰기 가능 파일 (`writable_files`) | 상태 (`status`) |' \
    'agent_assignments header does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| `<비민감 식별자>` | `Lead`, `Researcher`, `Implementer`, `Reviewer`, `Verifier` 중 하나 | `<담당 범위>` | `<저장소 상대 경로 또는 NONE>` | `COMPLETED`, `NEEDS_LEAD_DECISION`, `NEEDS_USER_APPROVAL`, `BLOCKED` 중 하나 |' \
    'agent_assignments placeholder row does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| 위임자 (`from`) | 수임자 (`to`) | 계약 요약 (`contract_summary`) | 결과 채택 (`result_adopted`) | 결과·근거 요약 (`result_evidence_summary`) |' \
    'delegations header does not match the extended trace contract'
  require_exact_line "$template_file" \
    '| `Lead` | `<비민감 식별자>` | `<목표·범위·금지 행동·evaluator>` | `ADOPTED`, `REJECTED`, `PARTIAL` 중 하나 | `<반환 결과와 채택 판단>` |' \
    'delegations placeholder row does not match the extended trace contract'
}

validate_report_template() {
  report_template_file=$1

  require_exact_line "$report_template_file" \
    '- `generated_at`: `YYYY-MM-DDThh:mm:ss+09:00`' \
    'generated_at template must use the +09:00 timezone offset'
  require_exact_line "$report_template_file" \
    '| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |' \
    'source_traces header does not match the report contract'
  require_exact_line "$report_template_file" \
    '| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |' \
    'signals header does not match the report contract'
}

validate_candidate_template() {
  candidate_template_file=$1

  require_exact_line "$candidate_template_file" \
    '- `created_at`: `YYYY-MM-DDThh:mm:ss+09:00`' \
    'created_at template must use the +09:00 timezone offset'
  require_exact_line "$candidate_template_file" \
    '| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |' \
    'comparison_results header does not match the candidate contract'
  require_exact_line "$candidate_template_file" \
    '| `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` |' \
    'comparison_results sentinel row does not match the candidate contract'
}

validate_candidate_comparisons() {
  candidate_file=$1
  candidate_status_value=$2
  minimum_pairs=$3

  if ! awk -v status="$candidate_status_value" -v minimum_pairs="$minimum_pairs" '
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
      in_comparisons = ($0 == "## 평가 결과 (`comparison_results`)")
      next
    }
    in_comparisons && /^\|/ {
      column_count = split($0, column, "|")
      first = bare(column[2])
      if (first ~ /comparison_id/ || first ~ /^-+$/) next
      if (column_count != 9) {
        print "comparison_results row must have seven columns"
        next
      }
      if (first == "NOT_EVALUATED") {
        sentinel_count++
        for (column_index = 2; column_index <= 8; column_index++) {
          if (bare(column[column_index]) != "NOT_EVALUATED") print "NOT_EVALUATED comparison row must use the sentinel in every column"
        }
        next
      }
      comparison_count++
      task_id = bare(column[3])
      evaluator_id = bare(column[4])
      baseline_trace = bare(column[5])
      candidate_trace = bare(column[6])
      quality_change = bare(column[7])
      if (first !~ /^cmp-[a-z0-9]+(-[a-z0-9]+)*-[0-9][0-9]$/) print "comparison_results row " comparison_count " has invalid comparison_id: " first
      else if (seen_comparison[first]++) print "duplicate comparison_id: " first
      if (task_id !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) print "comparison_results row " comparison_count " has invalid task_id: " task_id
      if (evaluator_id !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) print "comparison_results row " comparison_count " has invalid evaluator_id: " evaluator_id
      if (baseline_trace !~ /^tr-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9][0-9]$/) print "comparison_results row " comparison_count " has invalid baseline_trace_id: " baseline_trace
      if (candidate_trace !~ /^tr-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9][0-9]$/) print "comparison_results row " comparison_count " has invalid candidate_trace_id: " candidate_trace
      if (quality_change != "IMPROVED" && quality_change != "UNCHANGED" && quality_change != "DEGRADED" && quality_change != "BLOCKED") print "comparison_results row " comparison_count " has invalid quality_change: " quality_change
      if (quality_change == "IMPROVED") improved_count++
      if (quality_change == "DEGRADED") degraded_count++
      if (quality_change == "BLOCKED") blocked_count++
    }
    END {
      if (sentinel_count && comparison_count) print "NOT_EVALUATED cannot be mixed with completed comparison rows"
      if (sentinel_count > 1) print "comparison_results must contain at most one NOT_EVALUATED row"
      if (!sentinel_count && comparison_count == 0) print "no comparison_results rows found"
      if ((status == "DRAFT" || status == "READY" || status == "EVALUATING") && comparison_count == 0 && sentinel_count != 1) print "non-terminal candidate requires one NOT_EVALUATED row when no comparisons exist"
      if ((status == "ACCEPTED" || status == "PROMOTED" || status == "REJECTED") && comparison_count < minimum_pairs) print "terminal candidate has fewer comparison pairs than minimum_comparison_pairs"
      if ((status == "ACCEPTED" || status == "PROMOTED") && improved_count == 0) print status " candidate requires at least one IMPROVED comparison"
      if ((status == "ACCEPTED" || status == "PROMOTED") && (degraded_count || blocked_count)) print status " candidate cannot contain DEGRADED or BLOCKED comparisons"
    }
  ' "$candidate_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse candidate comparison results' > "$harness_diagnostics"
  fi
}

validate_candidate_trace_references() {
  reference_candidate_file=$1
  reference_candidate_status=$2
  reference_report_file=$3
  reference_candidate_relative=${reference_candidate_file#"$repo_root"/}

  if ! awk '
    function trim(value) { sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); return value }
    function bare(value) { value = trim(value); if (value ~ /^`[^`]+`$/) return substr(value, 2, length(value) - 2); return value }
    /^## / { in_comparisons = ($0 == "## 평가 결과 (`comparison_results`)"); next }
    in_comparisons && /^\|/ {
      column_count = split($0, column, "|")
      comparison_id = bare(column[2])
      if (comparison_id ~ /comparison_id/ || comparison_id ~ /^-+$/ || comparison_id == "NOT_EVALUATED" || column_count != 9) next
      printf "%s\t%s\t%s\n", bare(column[4]), bare(column[5]), bare(column[6])
    }
  ' "$reference_candidate_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse candidate trace references' > "$harness_diagnostics"
  fi

  while IFS='	' read -r reference_evaluator reference_baseline_trace reference_candidate_trace; do
    [ -n "$reference_baseline_trace" ] || continue
    if ! awk -v target="$reference_baseline_trace" '
      /^## / { in_sources = ($0 == "## Source Trace (`source_traces`)"); next }
      in_sources && index($0, "| `" target "` |") == 1 { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$reference_report_file"; then
      fail "$reference_candidate_relative: baseline trace is not in source report inventory: $reference_baseline_trace"
    fi
    if [ "$reference_baseline_trace" = "$reference_candidate_trace" ]; then
      fail "$reference_candidate_relative: comparison must use different baseline and candidate traces: $reference_baseline_trace"
    fi

    for reference_kind in baseline candidate; do
      case "$reference_kind" in
        baseline) reference_trace_id=$reference_baseline_trace ;;
        candidate) reference_trace_id=$reference_candidate_trace ;;
      esac
      reference_trace_file=$repo_root/.harness/traces/runs/$reference_trace_id.md
      if [ ! -f "$reference_trace_file" ]; then
        case "$reference_candidate_status" in
          PROMOTED|REJECTED|DEFERRED) continue ;;
          *) fail "$reference_candidate_relative: $reference_kind trace is missing: $reference_trace_id"; continue ;;
        esac
      fi
      if [ "$(field_value "$reference_trace_file" trace_id)" != "$reference_trace_id" ]; then
        fail "$reference_candidate_relative: $reference_kind trace_id differs from referenced file: $reference_trace_id"
      fi
      if [ "$reference_kind" = 'candidate' ]; then
        [ "$(field_value "$reference_trace_file" trace_level)" = 'extended' ] || \
          fail "$reference_candidate_relative: candidate trace must be extended: $reference_trace_id"
        [ "$(field_value "$reference_trace_file" trigger_repeated_evaluation)" = 'true' ] || \
          fail "$reference_candidate_relative: candidate trace must enable repeated evaluation: $reference_trace_id"
        if ! grep -Fq "| \`$reference_evaluator\` |" "$reference_trace_file"; then
          fail "$reference_candidate_relative: candidate trace does not contain evaluator result $reference_evaluator: $reference_trace_id"
        fi
      fi
    done
  done < "$harness_diagnostics"
}

validate_report_tables() {
  report_file=$1
  report_source_count=$2
  report_included_count=$3
  report_excluded_count=$4
  report_pass_count=$5
  report_fail_count=$6
  report_blocked_count=$7
  report_attempt_count=$8
  report_rework_count=$9
  shift 9
  report_unverified_count=$1
  report_risk_count=$2

  if ! awk \
    -v expected_source="$report_source_count" \
    -v expected_included="$report_included_count" \
    -v expected_excluded="$report_excluded_count" \
    -v expected_pass="$report_pass_count" \
    -v expected_fail="$report_fail_count" \
    -v expected_blocked="$report_blocked_count" \
    -v expected_attempts="$report_attempt_count" \
    -v expected_reworks="$report_rework_count" \
    -v expected_unverified="$report_unverified_count" \
    -v expected_risks="$report_risk_count" '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function bare(value) {
      value = trim(value)
      if (value ~ /^`[^`]+`$/) {
        return substr(value, 2, length(value) - 2)
      }
      return value
    }
    function compare_count(name, actual, expected) {
      if (actual != expected) {
        print name " does not match source_traces: expected " actual ", found " expected
      }
    }
    /^## / {
      in_sources = ($0 == "## Source Trace (`source_traces`)")
      in_signals = ($0 == "## 관찰 신호 (`signals`)")
      next
    }
    in_sources && /^\|/ {
      column_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /trace_id/ || first ~ /^-+$/) next
      source_count++
      if (column_count != 12) {
        print "source_traces row " source_count " must have ten columns"
        next
      }
      trace_id = bare(column[2])
      recorded_at = bare(column[3])
      task_type = bare(column[4])
      trace_level = bare(column[5])
      final_result = bare(column[6])
      attempts = bare(column[7])
      reworks = bare(column[8])
      has_unverified = bare(column[9])
      has_risk = bare(column[10])
      inclusion = bare(column[11])

      if (trace_id !~ /^tr-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9][0-9]$/) {
        print "source_traces row " source_count " has invalid trace_id: " trace_id
      } else if (seen_trace[trace_id]++) {
        print "duplicate source trace_id: " trace_id
      } else {
        source_trace[trace_id] = 1
      }
      if (recorded_at !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+09:00$/) {
        print "source_traces row " source_count " has invalid recorded_at: " recorded_at
      }
      if (task_type != "bug_fix" && task_type != "feature" && task_type != "behavior_change" && task_type != "repeated_work" && task_type != "code_review" && task_type != "other") {
        print "source_traces row " source_count " has invalid task_type: " task_type
      }
      if (trace_level != "minimum" && trace_level != "extended") {
        print "source_traces row " source_count " has invalid trace_level: " trace_level
      }
      if (final_result != "PASS" && final_result != "FAIL" && final_result != "BLOCKED") {
        print "source_traces row " source_count " has invalid final_result: " final_result
      }
      if (attempts !~ /^[1-9][0-9]*$/) print "source_traces row " source_count " has invalid attempt_count: " attempts
      if (reworks !~ /^[0-9]+$/) print "source_traces row " source_count " has invalid rework_count: " reworks
      if (has_unverified != "true" && has_unverified != "false") print "source_traces row " source_count " has invalid has_unverified: " has_unverified
      if (has_risk != "true" && has_risk != "false") print "source_traces row " source_count " has invalid has_remaining_risk: " has_risk
      if (inclusion != "INCLUDED" && inclusion != "EXCLUDED") {
        print "source_traces row " source_count " has invalid inclusion: " inclusion
        next
      }
      if (inclusion == "EXCLUDED") {
        excluded_count++
        next
      }
      included_count++
      if (final_result == "PASS") pass_count++
      else if (final_result == "FAIL") fail_count++
      else if (final_result == "BLOCKED") blocked_count++
      attempt_count += attempts
      rework_count += reworks
      if (has_unverified == "true") unverified_count++
      if (has_risk == "true") risk_count++
      next
    }
    in_signals && /^\|/ {
      column_count = split($0, column, "|")
      first = trim(column[2])
      if (first ~ /signal_id/ || first ~ /^-+$/) next
      signal_count++
      if (column_count != 9) {
        print "signals row " signal_count " must have seven columns"
        next
      }
      signal_id = bare(column[2])
      occurrence = bare(column[4])
      evidence = bare(column[5])
      status = bare(column[6])
      severity = bare(column[7])
      if (signal_id !~ /^SIG-[A-Z0-9-]+-[0-9][0-9]$/) print "signals row " signal_count " has invalid signal_id: " signal_id
      else if (seen_signal[signal_id]++) print "duplicate signal_id: " signal_id
      if (occurrence !~ /^[1-9][0-9]*$/) print "signals row " signal_count " has invalid occurrence_count: " occurrence
      evidence_count = split(evidence, evidence_id, ",")
      delete seen_evidence
      for (evidence_index = 1; evidence_index <= evidence_count; evidence_index++) {
        current_evidence = trim(evidence_id[evidence_index])
        if (seen_evidence[current_evidence]++) print "signals row " signal_count " has duplicate evidence_trace_id: " current_evidence
        if (!(current_evidence in source_trace)) print "signals row " signal_count " references trace outside source inventory: " current_evidence
      }
      if (occurrence ~ /^[1-9][0-9]*$/ && occurrence != evidence_count) print "signals row " signal_count " occurrence_count does not match evidence_trace_ids: expected " evidence_count ", found " occurrence
      if (status != "OPEN" && status != "RESOLVED" && status != "INSUFFICIENT_EVIDENCE") print "signals row " signal_count " has invalid status: " status
      if (severity != "LOW" && severity != "MEDIUM" && severity != "HIGH") print "signals row " signal_count " has invalid severity: " severity
    }
    END {
      if (source_count == 0) print "no source_traces rows found"
      if (signal_count == 0) print "no signals rows found"
      compare_count("source_trace_count", source_count, expected_source)
      compare_count("included_trace_count", included_count, expected_included)
      compare_count("excluded_trace_count", excluded_count, expected_excluded)
      compare_count("pass_count", pass_count, expected_pass)
      compare_count("fail_count", fail_count, expected_fail)
      compare_count("blocked_count", blocked_count, expected_blocked)
      compare_count("total_attempt_count", attempt_count, expected_attempts)
      compare_count("total_rework_count", rework_count, expected_reworks)
      compare_count("unverified_trace_count", unverified_count, expected_unverified)
      compare_count("remaining_risk_trace_count", risk_count, expected_risks)
    }
  ' "$report_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse report tables' > "$harness_diagnostics"
  fi
}

validate_report_source_references() {
  source_report_file=$1
  source_report_relative=${source_report_file#"$repo_root"/}

  if ! awk '
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
  ' "$source_report_file" > "$harness_diagnostics"; then
    printf '%s\n' 'could not parse report source references' > "$harness_diagnostics"
  fi

  while IFS='	' read -r source_trace_id source_recorded_at source_task_type source_trace_level source_final_result source_attempt_count source_rework_count source_has_unverified source_has_risk; do
    [ -n "$source_trace_id" ] || continue
    source_trace_file=$repo_root/.harness/traces/runs/$source_trace_id.md
    if [ ! -f "$source_trace_file" ]; then
      continue
    fi

    source_actual_unverified=true
    [ "$(field_value "$source_trace_file" unverified)" = 'NONE' ] && source_actual_unverified=false
    source_actual_risk=true
    [ "$(field_value "$source_trace_file" remaining_risks)" = 'NONE' ] && source_actual_risk=false

    for source_field in recorded_at task_type trace_level final_result attempt_count rework_count; do
      case "$source_field" in
        recorded_at) source_report_value=$source_recorded_at ;;
        task_type) source_report_value=$source_task_type ;;
        trace_level) source_report_value=$source_trace_level ;;
        final_result) source_report_value=$source_final_result ;;
        attempt_count) source_report_value=$source_attempt_count ;;
        rework_count) source_report_value=$source_rework_count ;;
      esac
      source_trace_value=$(field_value "$source_trace_file" "$source_field")
      if [ "$source_report_value" != "$source_trace_value" ]; then
        fail "$source_report_relative: source trace $source_trace_id $source_field differs from trace: report=$source_report_value trace=$source_trace_value"
      fi
    done

    if [ "$source_has_unverified" != "$source_actual_unverified" ]; then
      fail "$source_report_relative: source trace $source_trace_id has_unverified differs from trace: report=$source_has_unverified trace=$source_actual_unverified"
    fi
    if [ "$source_has_risk" != "$source_actual_risk" ]; then
      fail "$source_report_relative: source trace $source_trace_id has_remaining_risk differs from trace: report=$source_has_risk trace=$source_actual_risk"
    fi
  done < "$harness_diagnostics"
}

repo_skills=$(make_temp) || exit 1
installed_skills=$(make_temp) || exit 1
baseline_skills=$(make_temp) || exit 1
actual_system_skills=$(make_temp) || exit 1
link_errors=$(make_temp) || exit 1
broken_symlinks=$(make_temp) || exit 1
all_installed_skills=$(make_temp) || exit 1
extra_installed_skills=$(make_temp) || exit 1
harness_diagnostics=$(make_temp) || exit 1
trap 'rm -f "$repo_skills" "$installed_skills" "$baseline_skills" "$actual_system_skills" "$link_errors" "$broken_symlinks" "$all_installed_skills" "$extra_installed_skills" "$harness_diagnostics"' EXIT HUP INT TERM

printf '%s\n' '[Repository]'

if git -C "$repo_root" diff --check HEAD --; then
  pass 'git diff whitespace check'
else
  fail 'git diff contains whitespace errors'
fi

agents_changed=$(git -C "$repo_root" diff --name-only HEAD -- AGENTS.md)
korean_agents_changed=$(git -C "$repo_root" diff --name-only HEAD -- docs/AGENTS.ko.md)
if { [ -n "$agents_changed" ] && [ -z "$korean_agents_changed" ]; } || \
   { [ -z "$agents_changed" ] && [ -n "$korean_agents_changed" ]; }; then
  fail 'AGENTS.md and docs/AGENTS.ko.md must change together'
else
  pass 'AGENTS.md translation change pairing'
fi

configured_hooks_path=$(git -C "$repo_root" config --local --get core.hooksPath || true)
if [ "$configured_hooks_path" != '.githooks' ]; then
  fail 'core.hooksPath must be .githooks'
else
  pass 'core.hooksPath configuration'
fi

for hook_name in pre-push post-merge post-rewrite; do
  if [ ! -x "$repo_root/.githooks/$hook_name" ]; then
    fail ".githooks/$hook_name is missing or not executable"
  fi
done

for executable_script in scripts/setup.sh scripts/doctor.sh skills/skill-list/scripts/doctor.sh; do
  if [ ! -x "$repo_root/$executable_script" ]; then
    fail "$executable_script is missing or not executable"
  fi
done

for candidate_implementation_script in "$repo_root"/.harness/candidates/implementations/*/*.sh; do
  [ -f "$candidate_implementation_script" ] || continue
  if [ ! -x "$candidate_implementation_script" ]; then
    fail "${candidate_implementation_script#"$repo_root"/} is not executable"
  fi
done

shell_syntax_failed=0
for shell_script in \
  "$repo_root"/scripts/*.sh \
  "$repo_root"/skills/*/scripts/*.sh \
  "$repo_root"/.harness/candidates/implementations/*/*.sh \
  "$repo_root"/.githooks/*; do
  [ -f "$shell_script" ] || continue
  if ! sh -n "$shell_script"; then
    fail "shell syntax error: ${shell_script#"$repo_root"/}"
    shell_syntax_failed=1
  fi
done
if [ "$shell_syntax_failed" -eq 0 ]; then
  pass 'doctor and Git hook shell syntax'
fi

printf '%s\n' '[Harness]'

harness_errors_before=$error_count

for required_harness_file in \
  .harness/README.md \
  .harness/baseline/README.md \
  .harness/baseline/context-contract.md \
  .harness/baseline/terminology.md \
  .harness/baseline/version.md \
  .harness/policies/README.md \
  .harness/policies/approval-policy.md \
  .harness/policies/parallel-work-policy.md \
  .harness/roles/README.md \
  .harness/roles/lead.md \
  .harness/roles/researcher.md \
  .harness/roles/implementer.md \
  .harness/roles/reviewer.md \
  .harness/roles/verifier.md \
  .harness/tasks/README.md \
  .harness/tasks/templates/task-template.md \
  .harness/evaluators/README.md \
  .harness/evaluators/templates/evaluator-template.md \
  .harness/traces/README.md \
  .harness/traces/templates/minimum-trace.md \
  .harness/traces/templates/extended-trace.md \
  .harness/reports/README.md \
  .harness/reports/templates/report-template.md \
  .harness/candidates/README.md \
  .harness/candidates/templates/candidate-template.md; do
  if [ ! -f "$repo_root/$required_harness_file" ]; then
    fail "$required_harness_file is missing"
  fi
done

baseline_version_file=$repo_root/.harness/baseline/version.md
if [ -f "$baseline_version_file" ]; then
  validate_baseline_history "$baseline_version_file"
  while IFS= read -r baseline_diagnostic; do
    [ -n "$baseline_diagnostic" ] && fail ".harness/baseline/version.md: $baseline_diagnostic"
  done < "$harness_diagnostics"
fi

if [ -f "$repo_root/README.md" ]; then
  for root_harness_link in \
    .harness/README.md \
    .harness/baseline/README.md \
    .harness/tasks/README.md \
    .harness/evaluators/README.md \
    .harness/policies/README.md \
    .harness/roles/README.md \
    .harness/traces/README.md \
    .harness/reports/README.md \
    .harness/candidates/README.md; do
    require_index_link "$repo_root/README.md" "$root_harness_link" "$root_harness_link"
  done
fi

for harness_index_dir in baseline policies roles tasks evaluators reports candidates; do
  harness_index_file=$repo_root/.harness/$harness_index_dir/README.md
  [ -f "$harness_index_file" ] || continue
  for harness_index_document in "$repo_root/.harness/$harness_index_dir"/*.md; do
    [ -f "$harness_index_document" ] || continue
    harness_index_name=$(basename -- "$harness_index_document")
    [ "$harness_index_name" = 'README.md' ] && continue
    require_index_link "$harness_index_file" "$harness_index_name" \
      ".harness/$harness_index_dir/$harness_index_name"
  done
done

if [ -f "$repo_root/.harness/tasks/README.md" ]; then
  require_index_link "$repo_root/.harness/tasks/README.md" 'templates/task-template.md' \
    '.harness/tasks/templates/task-template.md'
fi
if [ -f "$repo_root/.harness/evaluators/README.md" ]; then
  require_index_link "$repo_root/.harness/evaluators/README.md" 'templates/evaluator-template.md' \
    '.harness/evaluators/templates/evaluator-template.md'
fi
if [ -f "$repo_root/.harness/traces/README.md" ]; then
  require_index_link "$repo_root/.harness/traces/README.md" 'templates/minimum-trace.md' \
    '.harness/traces/templates/minimum-trace.md'
  require_index_link "$repo_root/.harness/traces/README.md" 'templates/extended-trace.md' \
    '.harness/traces/templates/extended-trace.md'
fi
if [ -f "$repo_root/.harness/reports/README.md" ]; then
  require_index_link "$repo_root/.harness/reports/README.md" 'templates/report-template.md' \
    '.harness/reports/templates/report-template.md'
fi
if [ -f "$repo_root/.harness/candidates/README.md" ]; then
  require_index_link "$repo_root/.harness/candidates/README.md" 'templates/candidate-template.md' \
    '.harness/candidates/templates/candidate-template.md'
fi

task_count=0
for task_file in "$repo_root"/.harness/tasks/*.md; do
  [ -f "$task_file" ] || continue
  [ "$(basename -- "$task_file")" = 'README.md' ] && continue
  task_count=$((task_count + 1))
  task_relative=${task_file#"$repo_root"/}

  for task_key in schema_version task_id task_type evaluator_id default_trace_level; do
    require_scalar_field "$task_file" "$task_key" || true
  done
  for task_heading in '## 적용 조건' '## 제외 조건' '## 필수 입력' '## 범위' '## 금지 행동' '## 성공 조건 (`acceptance_criteria`)' '## Evaluator 전달 계약'; do
    require_heading "$task_file" "$task_heading"
  done

  task_schema=$(field_value "$task_file" schema_version)
  task_id=$(field_value "$task_file" task_id)
  task_type=$(field_value "$task_file" task_type)
  task_evaluator_id=$(field_value "$task_file" evaluator_id)
  task_trace_level=$(field_value "$task_file" default_trace_level)

  [ "$task_schema" = '1' ] || fail "$task_relative: unsupported schema_version: $task_schema"
  if ! valid_kebab_id "$task_id"; then
    fail "$task_relative: invalid task_id: $task_id"
  elif [ "$(basename -- "$task_file" .md)" != "$task_id" ]; then
    fail "$task_relative: file name must match task_id $task_id"
  fi
  case "$task_type" in
    bug_fix|feature|behavior_change|repeated_work|code_review|other) ;;
    *) fail "$task_relative: invalid task_type: $task_type" ;;
  esac
  case "$task_trace_level" in
    minimum|extended) ;;
    *) fail "$task_relative: invalid default_trace_level: $task_trace_level" ;;
  esac
  if ! valid_kebab_id "$task_evaluator_id"; then
    fail "$task_relative: invalid evaluator_id: $task_evaluator_id"
  elif [ ! -f "$repo_root/.harness/evaluators/$task_evaluator_id.md" ]; then
    fail "$task_relative: evaluator is missing: $task_evaluator_id"
  fi

  validate_task_acceptance "$task_file"
  while IFS= read -r acceptance_diagnostic; do
    [ -n "$acceptance_diagnostic" ] && fail "$task_relative: $acceptance_diagnostic"
  done < "$harness_diagnostics"
done
if [ "$task_count" -eq 0 ]; then
  fail 'no Harness task documents found'
fi

evaluator_count=0
for evaluator_file in "$repo_root"/.harness/evaluators/*.md; do
  [ -f "$evaluator_file" ] || continue
  [ "$(basename -- "$evaluator_file")" = 'README.md' ] && continue
  evaluator_count=$((evaluator_count + 1))
  evaluator_relative=${evaluator_file#"$repo_root"/}

  for evaluator_key in schema_version evaluator_id task_id; do
    require_scalar_field "$evaluator_file" "$evaluator_key" || true
  done
  for evaluator_heading in '## 사전 조건' '## 검사 (`evaluation_checks`)' '## 검사별 판정' '## 전체 판정' '## Trace 반환'; do
    require_heading "$evaluator_file" "$evaluator_heading"
  done

  evaluator_schema=$(field_value "$evaluator_file" schema_version)
  evaluator_id=$(field_value "$evaluator_file" evaluator_id)
  evaluator_task_id=$(field_value "$evaluator_file" task_id)

  [ "$evaluator_schema" = '1' ] || fail "$evaluator_relative: unsupported schema_version: $evaluator_schema"
  if ! valid_kebab_id "$evaluator_id"; then
    fail "$evaluator_relative: invalid evaluator_id: $evaluator_id"
  elif [ "$(basename -- "$evaluator_file" .md)" != "$evaluator_id" ]; then
    fail "$evaluator_relative: file name must match evaluator_id $evaluator_id"
  fi
  if ! valid_kebab_id "$evaluator_task_id"; then
    fail "$evaluator_relative: invalid task_id: $evaluator_task_id"
  elif [ ! -f "$repo_root/.harness/tasks/$evaluator_task_id.md" ]; then
    fail "$evaluator_relative: task is missing: $evaluator_task_id"
  elif [ "$(field_value "$repo_root/.harness/tasks/$evaluator_task_id.md" evaluator_id)" != "$evaluator_id" ]; then
    fail "$evaluator_relative: task $evaluator_task_id does not reference evaluator $evaluator_id"
  fi

  if [ -f "$repo_root/.harness/tasks/$evaluator_task_id.md" ]; then
    validate_evaluator_mapping "$evaluator_file" "$repo_root/.harness/tasks/$evaluator_task_id.md"
    while IFS= read -r mapping_diagnostic; do
      [ -n "$mapping_diagnostic" ] && fail "$evaluator_relative: $mapping_diagnostic"
    done < "$harness_diagnostics"
  fi
done
if [ "$evaluator_count" -eq 0 ]; then
  fail 'no Harness evaluator documents found'
elif [ "$evaluator_count" -ne "$task_count" ]; then
  fail "Harness task/evaluator count differs: tasks=$task_count evaluators=$evaluator_count"
fi

for trace_template in \
  "$repo_root/.harness/traces/templates/minimum-trace.md" \
  "$repo_root/.harness/traces/templates/extended-trace.md"; do
  [ -f "$trace_template" ] || continue
  for trace_key in schema_version trace_id recorded_at baseline_version trace_level final_result task_type task_reference request_summary in_scope out_of_scope applied_skills changed_files change_summary approval_summary external_actions attempt_count rework_count rework_summary unverified remaining_risks result_reason user_report_consistency; do
    require_scalar_field "$trace_template" "$trace_key" || true
  done
  for trace_heading in '## 메타데이터' '## 작업' '## 성공 조건 (`success_criteria`)' '## 적용 Skill' '## 변경' '## 시도와 재작업' '## 검증 결과 (`evaluator_results`)' '## 미검증 항목과 남은 위험' '## 최종 판정'; do
    require_heading "$trace_template" "$trace_heading"
  done
  trace_template_kind=minimum
  [ "$(basename -- "$trace_template")" = 'extended-trace.md' ] && trace_template_kind=extended
  validate_trace_template "$trace_template" "$trace_template_kind"
done

extended_template=$repo_root/.harness/traces/templates/extended-trace.md
if [ -f "$extended_template" ]; then
  for extended_key in trigger_high_risk trigger_repeated_evaluation trigger_multi_agent external_action_details failure_observed recovery_decision recovery_result run_id comparison_target controlled_inputs rework_cause comparison_limitations role_separation ownership_conflicts escalations integrated_by adopted_changes rejected_or_reworked_results integration_evaluator independence_limitations; do
    require_scalar_field "$extended_template" "$extended_key" || true
  done
  for extended_heading in '## 확장 메타데이터' '## 고위험 근거 (`high_risk_evidence`)' '### 위험 (`risks`)' '### 승인 (`approvals`)' '### 외부 행동과 복구 (`external_actions_recovery`)' '## 반복 평가 근거 (`repeated_evaluation_evidence`)' '### 비교 결과 (`comparison_results`)' '## 멀티에이전트 근거 (`multi_agent_evidence`)' '### 역할 배정과 소유권 (`agent_assignments`)' '### 위임과 역할 결과 (`delegations`)' '### 통합과 최종 검증 (`integration_verification`)'; do
    require_heading "$extended_template" "$extended_heading"
  done
fi

for trace_file in "$repo_root"/.harness/traces/runs/*.md; do
  [ -f "$trace_file" ] || continue
  trace_relative=${trace_file#"$repo_root"/}
  for trace_key in schema_version trace_id recorded_at baseline_version trace_level final_result task_type task_reference request_summary in_scope out_of_scope applied_skills changed_files change_summary approval_summary external_actions attempt_count rework_count rework_summary unverified remaining_risks result_reason user_report_consistency; do
    require_scalar_field "$trace_file" "$trace_key" || true
  done
  for trace_heading in '## 메타데이터' '## 작업' '## 성공 조건 (`success_criteria`)' '## 적용 Skill' '## 변경' '## 시도와 재작업' '## 검증 결과 (`evaluator_results`)' '## 미검증 항목과 남은 위험' '## 최종 판정'; do
    require_heading "$trace_file" "$trace_heading"
  done

  trace_schema=$(field_value "$trace_file" schema_version)
  trace_id=$(field_value "$trace_file" trace_id)
  trace_level=$(field_value "$trace_file" trace_level)
  trace_result=$(field_value "$trace_file" final_result)
  trace_task_type=$(field_value "$trace_file" task_type)
  trace_recorded_at=$(field_value "$trace_file" recorded_at)
  trace_attempt_count=$(field_value "$trace_file" attempt_count)
  trace_rework_count=$(field_value "$trace_file" rework_count)
  trace_report_consistency=$(field_value "$trace_file" user_report_consistency)

  [ "$trace_schema" = '1' ] || fail "$trace_relative: unsupported schema_version: $trace_schema"
  validate_known_baseline_version "$trace_file" "$trace_relative"
  if ! printf '%s\n' "$trace_id" | grep -Eq '^tr-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{2}$'; then
    fail "$trace_relative: invalid trace_id: $trace_id"
  elif [ "$(basename -- "$trace_file" .md)" != "$trace_id" ]; then
    fail "$trace_relative: file name must match trace_id $trace_id"
  fi
  if ! printf '%s\n' "$trace_recorded_at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+09:00$'; then
    fail "$trace_relative: recorded_at must be ISO 8601 with the +09:00 timezone offset"
  fi
  case "$trace_level" in
    minimum|extended) ;;
    *) fail "$trace_relative: invalid trace_level: $trace_level" ;;
  esac
  case "$trace_result" in
    PASS|FAIL|BLOCKED) ;;
    *) fail "$trace_relative: invalid final_result: $trace_result" ;;
  esac
  case "$trace_task_type" in
    bug_fix|feature|behavior_change|repeated_work|code_review|other) ;;
    *) fail "$trace_relative: invalid task_type: $trace_task_type" ;;
  esac
  case "$trace_attempt_count" in
    ''|*[!0-9]*|0) fail "$trace_relative: attempt_count must be a positive integer" ;;
  esac
  case "$trace_rework_count" in
    ''|*[!0-9]*) fail "$trace_relative: rework_count must be a non-negative integer" ;;
  esac
  case "$trace_report_consistency" in
    CONSISTENT|INCONSISTENT|PENDING) ;;
    *) fail "$trace_relative: invalid user_report_consistency: $trace_report_consistency" ;;
  esac
  if grep -Eq '<[^>]+>' "$trace_file"; then
    fail "$trace_relative: unresolved placeholder found"
  fi
  if grep -Eq '/Users/[^/]+/|/home/[^/]+/' "$trace_file"; then
    fail "$trace_relative: absolute user path found"
  fi
  if grep -Eq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[^[:alnum:]])(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,})' "$trace_file"; then
    fail "$trace_relative: possible unmasked secret found"
  fi
  validate_trace_results "$trace_file" "$trace_result"
  while IFS= read -r trace_diagnostic; do
    [ -n "$trace_diagnostic" ] && fail "$trace_relative: $trace_diagnostic"
  done < "$harness_diagnostics"

  if [ "$trace_level" = 'extended' ]; then
    for extended_key in trigger_high_risk trigger_repeated_evaluation trigger_multi_agent external_action_details failure_observed recovery_decision recovery_result run_id comparison_target controlled_inputs rework_cause comparison_limitations role_separation ownership_conflicts escalations integrated_by adopted_changes rejected_or_reworked_results integration_evaluator independence_limitations; do
      require_scalar_field "$trace_file" "$extended_key" || true
    done
    for extended_heading in '## 확장 메타데이터' '## 고위험 근거 (`high_risk_evidence`)' '### 위험 (`risks`)' '### 승인 (`approvals`)' '### 외부 행동과 복구 (`external_actions_recovery`)' '## 반복 평가 근거 (`repeated_evaluation_evidence`)' '### 비교 결과 (`comparison_results`)' '## 멀티에이전트 근거 (`multi_agent_evidence`)' '### 역할 배정과 소유권 (`agent_assignments`)' '### 위임과 역할 결과 (`delegations`)' '### 통합과 최종 검증 (`integration_verification`)'; do
      require_heading "$trace_file" "$extended_heading"
    done

    for extended_trigger_key in trigger_high_risk trigger_repeated_evaluation trigger_multi_agent; do
      extended_trigger=$(field_value "$trace_file" "$extended_trigger_key")
      case "$extended_trigger" in
        true|false) ;;
        *) fail "$trace_relative: invalid $extended_trigger_key: $extended_trigger" ;;
      esac
    done

    check_extended_scalar_group "$trace_file" "$(field_value "$trace_file" trigger_high_risk)" \
      external_action_details failure_observed recovery_decision recovery_result
    check_extended_scalar_group "$trace_file" "$(field_value "$trace_file" trigger_repeated_evaluation)" \
      run_id comparison_target controlled_inputs rework_cause comparison_limitations
    check_extended_scalar_group "$trace_file" "$(field_value "$trace_file" trigger_multi_agent)" \
      role_separation ownership_conflicts escalations integrated_by adopted_changes \
      rejected_or_reworked_results integration_evaluator independence_limitations

    validate_extended_tables \
      "$trace_file" \
      "$(field_value "$trace_file" trigger_high_risk)" \
      "$(field_value "$trace_file" trigger_repeated_evaluation)" \
      "$(field_value "$trace_file" trigger_multi_agent)"
    while IFS= read -r table_diagnostic; do
      [ -n "$table_diagnostic" ] && fail "$trace_relative: $table_diagnostic"
    done < "$harness_diagnostics"
  fi
done

report_template=$repo_root/.harness/reports/templates/report-template.md
if [ -f "$report_template" ]; then
  for report_key in schema_version report_id generated_at baseline_version report_status comparison_readiness window_start window_end selection_rule aggregation_method limitations source_trace_count included_trace_count excluded_trace_count pass_count fail_count blocked_count total_attempt_count total_rework_count unverified_trace_count remaining_risk_trace_count candidate_recommendation candidate_reason recommended_evaluation conclusion; do
    require_scalar_field "$report_template" "$report_key" || true
  done
  for report_heading in '## 메타데이터' '## 집계 범위' '## Source Trace (`source_traces`)' '## 집계 (`aggregate_counts`)' '## 관찰 신호 (`signals`)' '## Candidate 판단' '## 결론'; do
    require_heading "$report_template" "$report_heading"
  done
  validate_report_template "$report_template"
fi

report_count=0
for report_file in "$repo_root"/.harness/reports/*.md; do
  [ -f "$report_file" ] || continue
  [ "$(basename -- "$report_file")" = 'README.md' ] && continue
  report_count=$((report_count + 1))
  report_relative=${report_file#"$repo_root"/}

  for report_key in schema_version report_id generated_at baseline_version report_status comparison_readiness window_start window_end selection_rule aggregation_method limitations source_trace_count included_trace_count excluded_trace_count pass_count fail_count blocked_count total_attempt_count total_rework_count unverified_trace_count remaining_risk_trace_count candidate_recommendation candidate_reason recommended_evaluation conclusion; do
    require_scalar_field "$report_file" "$report_key" || true
  done
  for report_heading in '## 메타데이터' '## 집계 범위' '## Source Trace (`source_traces`)' '## 집계 (`aggregate_counts`)' '## 관찰 신호 (`signals`)' '## Candidate 판단' '## 결론'; do
    require_heading "$report_file" "$report_heading"
  done

  report_schema=$(field_value "$report_file" schema_version)
  report_id=$(field_value "$report_file" report_id)
  report_generated_at=$(field_value "$report_file" generated_at)
  report_window_start=$(field_value "$report_file" window_start)
  report_window_end=$(field_value "$report_file" window_end)
  report_status=$(field_value "$report_file" report_status)
  report_readiness=$(field_value "$report_file" comparison_readiness)
  report_candidate=$(field_value "$report_file" candidate_recommendation)

  [ "$report_schema" = '1' ] || fail "$report_relative: unsupported schema_version: $report_schema"
  validate_known_baseline_version "$report_file" "$report_relative"
  if ! printf '%s\n' "$report_id" | grep -Eq '^rp-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{2}$'; then
    fail "$report_relative: invalid report_id: $report_id"
  elif [ "$(basename -- "$report_file" .md)" != "$report_id" ]; then
    fail "$report_relative: file name must match report_id $report_id"
  fi
  for report_time_value in "$report_generated_at" "$report_window_start" "$report_window_end"; do
    if ! printf '%s\n' "$report_time_value" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+09:00$'; then
      fail "$report_relative: report timestamps must use ISO 8601 with the +09:00 timezone offset"
      break
    fi
  done
  case "$report_status" in
    READY|LIMITED|BLOCKED) ;;
    *) fail "$report_relative: invalid report_status: $report_status" ;;
  esac
  case "$report_readiness" in
    READY|LIMITED) ;;
    *) fail "$report_relative: invalid comparison_readiness: $report_readiness" ;;
  esac
  case "$report_candidate" in
    CREATE|DEFER|NONE) ;;
    *) fail "$report_relative: invalid candidate_recommendation: $report_candidate" ;;
  esac
  for report_count_key in source_trace_count included_trace_count excluded_trace_count pass_count fail_count blocked_count total_attempt_count total_rework_count unverified_trace_count remaining_risk_trace_count; do
    report_count_value=$(field_value "$report_file" "$report_count_key")
    case "$report_count_value" in
      ''|*[!0-9]*) fail "$report_relative: $report_count_key must be a non-negative integer" ;;
    esac
  done
  if grep -Eq '<[^>]+>' "$report_file"; then
    fail "$report_relative: unresolved placeholder found"
  fi
  if grep -Eq '/Users/[^/]+/|/home/[^/]+/' "$report_file"; then
    fail "$report_relative: absolute user path found"
  fi
  if grep -Eq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[^[:alnum:]])(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,})' "$report_file"; then
    fail "$report_relative: possible unmasked secret found"
  fi

  validate_report_tables \
    "$report_file" \
    "$(field_value "$report_file" source_trace_count)" \
    "$(field_value "$report_file" included_trace_count)" \
    "$(field_value "$report_file" excluded_trace_count)" \
    "$(field_value "$report_file" pass_count)" \
    "$(field_value "$report_file" fail_count)" \
    "$(field_value "$report_file" blocked_count)" \
    "$(field_value "$report_file" total_attempt_count)" \
    "$(field_value "$report_file" total_rework_count)" \
    "$(field_value "$report_file" unverified_trace_count)" \
    "$(field_value "$report_file" remaining_risk_trace_count)"
  while IFS= read -r report_diagnostic; do
    [ -n "$report_diagnostic" ] && fail "$report_relative: $report_diagnostic"
  done < "$harness_diagnostics"
  validate_report_source_references "$report_file"
done
if [ "$report_count" -eq 0 ]; then
  fail 'no Harness report documents found'
fi

candidate_template=$repo_root/.harness/candidates/templates/candidate-template.md
if [ -f "$candidate_template" ]; then
  for candidate_key in schema_version candidate_id created_at baseline_version candidate_status promoted_at promoted_version promotion_trace_id source_report_id source_signal_ids problem_statement evidence_summary change_summary target_files expected_effect non_goals rollback_plan affected_task_ids affected_evaluator_ids controlled_inputs minimum_comparison_pairs evaluation_commands regression_scope evaluation_result promotion_recommendation decision_reason remaining_risks approved_by; do
    require_scalar_field "$candidate_template" "$candidate_key" || true
  done
  for candidate_heading in '## 메타데이터' '## 근거 (`source_evidence`)' '## 개선안 (`proposed_change`)' '## 평가 계획 (`evaluation_plan`)' '## 평가 결과 (`comparison_results`)' '## 판정'; do
    require_heading "$candidate_template" "$candidate_heading"
  done
  validate_candidate_template "$candidate_template"
fi

for candidate_file in "$repo_root"/.harness/candidates/*.md; do
  [ -f "$candidate_file" ] || continue
  [ "$(basename -- "$candidate_file")" = 'README.md' ] && continue
  candidate_relative=${candidate_file#"$repo_root"/}

  for candidate_key in schema_version candidate_id created_at baseline_version candidate_status promoted_at promoted_version promotion_trace_id source_report_id source_signal_ids problem_statement evidence_summary change_summary target_files expected_effect non_goals rollback_plan affected_task_ids affected_evaluator_ids controlled_inputs minimum_comparison_pairs evaluation_commands regression_scope evaluation_result promotion_recommendation decision_reason remaining_risks approved_by; do
    require_scalar_field "$candidate_file" "$candidate_key" || true
  done
  for candidate_heading in '## 메타데이터' '## 근거 (`source_evidence`)' '## 개선안 (`proposed_change`)' '## 평가 계획 (`evaluation_plan`)' '## 평가 결과 (`comparison_results`)' '## 판정'; do
    require_heading "$candidate_file" "$candidate_heading"
  done

  candidate_schema=$(field_value "$candidate_file" schema_version)
  candidate_id=$(field_value "$candidate_file" candidate_id)
  candidate_created_at=$(field_value "$candidate_file" created_at)
  candidate_status=$(field_value "$candidate_file" candidate_status)
  candidate_promoted_at=$(field_value "$candidate_file" promoted_at)
  candidate_promoted_version=$(field_value "$candidate_file" promoted_version)
  candidate_promotion_trace=$(field_value "$candidate_file" promotion_trace_id)
  candidate_source_report=$(field_value "$candidate_file" source_report_id)
  candidate_source_signals=$(field_value "$candidate_file" source_signal_ids)
  candidate_tasks=$(field_value "$candidate_file" affected_task_ids)
  candidate_evaluators=$(field_value "$candidate_file" affected_evaluator_ids)
  candidate_minimum_pairs=$(field_value "$candidate_file" minimum_comparison_pairs)
  candidate_evaluation=$(field_value "$candidate_file" evaluation_result)
  candidate_promotion=$(field_value "$candidate_file" promotion_recommendation)
  candidate_approved_by=$(field_value "$candidate_file" approved_by)

  [ "$candidate_schema" = '1' ] || fail "$candidate_relative: unsupported schema_version: $candidate_schema"
  validate_known_baseline_version "$candidate_file" "$candidate_relative"
  if ! printf '%s\n' "$candidate_id" | grep -Eq '^cd-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{2}$'; then
    fail "$candidate_relative: invalid candidate_id: $candidate_id"
  elif [ "$(basename -- "$candidate_file" .md)" != "$candidate_id" ]; then
    fail "$candidate_relative: file name must match candidate_id $candidate_id"
  fi
  if ! printf '%s\n' "$candidate_created_at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+09:00$'; then
    fail "$candidate_relative: created_at must be ISO 8601 with the +09:00 timezone offset"
  fi
  case "$candidate_status" in
    DRAFT|READY|EVALUATING|ACCEPTED|PROMOTED|REJECTED|DEFERRED) ;;
    *) fail "$candidate_relative: invalid candidate_status: $candidate_status" ;;
  esac
  case "$candidate_evaluation" in
    PENDING|IMPROVED|UNCHANGED|DEGRADED|BLOCKED) ;;
    *) fail "$candidate_relative: invalid evaluation_result: $candidate_evaluation" ;;
  esac
  case "$candidate_promotion" in
    PENDING|PROMOTE|REVISE|REJECT) ;;
    *) fail "$candidate_relative: invalid promotion_recommendation: $candidate_promotion" ;;
  esac
  case "$candidate_minimum_pairs" in
    ''|*[!0-9]*|0) fail "$candidate_relative: minimum_comparison_pairs must be a positive integer" ;;
  esac

  case "$candidate_status" in
    DRAFT|READY|EVALUATING)
      [ "$candidate_evaluation" = 'PENDING' ] || fail "$candidate_relative: $candidate_status requires evaluation_result PENDING"
      [ "$candidate_promotion" = 'PENDING' ] || fail "$candidate_relative: $candidate_status requires promotion_recommendation PENDING"
      ;;
    ACCEPTED|PROMOTED)
      [ "$candidate_evaluation" = 'IMPROVED' ] || fail "$candidate_relative: $candidate_status requires evaluation_result IMPROVED"
      [ "$candidate_promotion" = 'PROMOTE' ] || fail "$candidate_relative: $candidate_status requires promotion_recommendation PROMOTE"
      ;;
    REJECTED)
      case "$candidate_evaluation" in UNCHANGED|DEGRADED) ;; *) fail "$candidate_relative: REJECTED requires evaluation_result UNCHANGED or DEGRADED" ;; esac
      case "$candidate_promotion" in REVISE|REJECT) ;; *) fail "$candidate_relative: REJECTED requires promotion_recommendation REVISE or REJECT" ;; esac
      ;;
    DEFERRED)
      [ "$candidate_evaluation" = 'BLOCKED' ] || fail "$candidate_relative: DEFERRED requires evaluation_result BLOCKED"
      case "$candidate_promotion" in PENDING|REVISE) ;; *) fail "$candidate_relative: DEFERRED requires promotion_recommendation PENDING or REVISE" ;; esac
      ;;
  esac

  if [ "$candidate_status" = 'PROMOTED' ]; then
    if ! printf '%s\n' "$candidate_promoted_at" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+09:00$'; then
      fail "$candidate_relative: PROMOTED requires promoted_at with the +09:00 timezone offset"
    fi
    if ! printf '%s\n' "$candidate_promoted_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$' || \
       ! grep -Fq "| \`$candidate_promoted_version\` |" "$repo_root/.harness/baseline/version.md"; then
      fail "$candidate_relative: PROMOTED requires a known promoted_version: $candidate_promoted_version"
    fi
    if ! printf '%s\n' "$candidate_promotion_trace" | grep -Eq '^tr-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9][0-9]$'; then
      fail "$candidate_relative: PROMOTED requires a valid promotion_trace_id: $candidate_promotion_trace"
    elif ! grep -Fq "\`$candidate_promotion_trace\`" "$repo_root/.harness/baseline/version.md"; then
      fail "$candidate_relative: promotion_trace_id is not recorded in baseline history: $candidate_promotion_trace"
    fi
    case "$candidate_approved_by" in PENDING|NOT_APPLICABLE) fail "$candidate_relative: PROMOTED requires approved_by" ;; esac
    candidate_promotion_trace_file=$repo_root/.harness/traces/runs/$candidate_promotion_trace.md
    if [ -f "$candidate_promotion_trace_file" ]; then
      [ "$(field_value "$candidate_promotion_trace_file" final_result)" = 'PASS' ] || \
        fail "$candidate_relative: promotion trace must have final_result PASS: $candidate_promotion_trace"
      [ "$(field_value "$candidate_promotion_trace_file" baseline_version)" = "$candidate_promoted_version" ] || \
        fail "$candidate_relative: promotion trace baseline_version differs from promoted_version: $candidate_promotion_trace"
      [ "$(field_value "$candidate_promotion_trace_file" task_reference)" = "$candidate_relative" ] || \
        fail "$candidate_relative: promotion trace task_reference must point to candidate: $candidate_promotion_trace"
    fi
  else
    for candidate_promotion_field in promoted_at promoted_version promotion_trace_id; do
      [ "$(field_value "$candidate_file" "$candidate_promotion_field")" = 'NOT_APPLICABLE' ] || \
        fail "$candidate_relative: $candidate_promotion_field must be NOT_APPLICABLE unless candidate_status is PROMOTED"
    done
  fi

  candidate_report_file=$repo_root/.harness/reports/$candidate_source_report.md
  if ! printf '%s\n' "$candidate_source_report" | grep -Eq '^rp-[0-9]{8}-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{2}$'; then
    fail "$candidate_relative: invalid source_report_id: $candidate_source_report"
  elif [ ! -f "$candidate_report_file" ]; then
    fail "$candidate_relative: source report is missing: $candidate_source_report"
  else
    [ "$(field_value "$candidate_report_file" candidate_recommendation)" = 'CREATE' ] || \
      fail "$candidate_relative: source report must have candidate_recommendation CREATE: $candidate_source_report"
    [ "$(field_value "$candidate_report_file" comparison_readiness)" = 'READY' ] || \
      fail "$candidate_relative: source report must have comparison_readiness READY: $candidate_source_report"
    old_ifs=$IFS
    IFS=,
    for candidate_signal in $candidate_source_signals; do
      candidate_signal=$(printf '%s' "$candidate_signal" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if ! printf '%s\n' "$candidate_signal" | grep -Eq '^SIG-[A-Z0-9-]+-[0-9]{2}$'; then
        fail "$candidate_relative: invalid source signal_id: $candidate_signal"
      elif ! grep -Fq "| \`$candidate_signal\` |" "$candidate_report_file"; then
        fail "$candidate_relative: source signal is missing from report: $candidate_signal"
      elif ! grep -F "| \`$candidate_signal\` |" "$candidate_report_file" | grep -Fq '| `OPEN` |'; then
        fail "$candidate_relative: source signal must be OPEN: $candidate_signal"
      fi
    done
    IFS=$old_ifs
  fi

  old_ifs=$IFS
  candidate_evaluators_normalized=$(printf '%s' "$candidate_evaluators" | tr -d '[:space:]')
  IFS=,
  for candidate_task in $candidate_tasks; do
    candidate_task=$(printf '%s' "$candidate_task" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if ! valid_kebab_id "$candidate_task" || [ ! -f "$repo_root/.harness/tasks/$candidate_task.md" ]; then
      fail "$candidate_relative: affected task is missing or invalid: $candidate_task"
    else
      candidate_task_evaluator=$(field_value "$repo_root/.harness/tasks/$candidate_task.md" evaluator_id)
      case ",$candidate_evaluators_normalized," in
        *",$candidate_task_evaluator,"*) ;;
        *) fail "$candidate_relative: affected_evaluator_ids must include $candidate_task_evaluator for task $candidate_task" ;;
      esac
    fi
  done
  for candidate_evaluator in $candidate_evaluators; do
    candidate_evaluator=$(printf '%s' "$candidate_evaluator" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if ! valid_kebab_id "$candidate_evaluator" || [ ! -f "$repo_root/.harness/evaluators/$candidate_evaluator.md" ]; then
      fail "$candidate_relative: affected evaluator is missing or invalid: $candidate_evaluator"
    fi
  done
  IFS=$old_ifs

  if grep -Eq '<[^>]+>' "$candidate_file"; then
    fail "$candidate_relative: unresolved placeholder found"
  fi
  if grep -Eq '/Users/[^/]+/|/home/[^/]+/' "$candidate_file"; then
    fail "$candidate_relative: absolute user path found"
  fi
  if grep -Eq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[^[:alnum:]])(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,})' "$candidate_file"; then
    fail "$candidate_relative: possible unmasked secret found"
  fi

  validate_candidate_comparisons "$candidate_file" "$candidate_status" "$candidate_minimum_pairs"
  while IFS= read -r candidate_diagnostic; do
    [ -n "$candidate_diagnostic" ] && fail "$candidate_relative: $candidate_diagnostic"
  done < "$harness_diagnostics"
  if [ -f "$candidate_report_file" ]; then
    validate_candidate_trace_references "$candidate_file" "$candidate_status" "$candidate_report_file"
  fi
done

if [ "$error_count" -eq "$harness_errors_before" ]; then
  pass 'Harness structure and contracts'
fi

printf '%s\n' '[Skills]'

for skill_md in "$repo_root"/skills/*/SKILL.md; do
  if [ ! -f "$skill_md" ]; then
    fail 'no repository skills found'
    break
  fi

  skill_dir=$(dirname -- "$skill_md")
  skill_name=$(basename -- "$skill_dir")
  printf '%s\n' "$skill_name" >> "$repo_skills"

  first_line=$(sed -n '1p' "$skill_md")
  frontmatter_end=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$skill_md")
  declared_name=$(awk 'NR > 1 && /^---$/ { exit } /^name:[[:space:]]*/ { sub(/^name:[[:space:]]*/, ""); print; exit }' "$skill_md" | tr -d '"')
  description=$(awk 'NR > 1 && /^---$/ { exit } /^description:[[:space:]]*/ { sub(/^description:[[:space:]]*/, ""); print; exit }' "$skill_md")

  if [ "$first_line" != '---' ] || [ -z "$frontmatter_end" ]; then
    fail "$skill_name: invalid SKILL.md frontmatter boundary"
  elif [ "$declared_name" != "$skill_name" ]; then
    fail "$skill_name: frontmatter name does not match directory"
  elif [ -z "$description" ]; then
    fail "$skill_name: description is empty"
  fi

  metadata_file=$skill_dir/agents/openai.yaml
  if [ ! -f "$metadata_file" ]; then
    fail "$skill_name: agents/openai.yaml is missing"
  elif ! grep -Eq '^interface:[[:space:]]*$' "$metadata_file" || \
       ! grep -Eq '^[[:space:]]+display_name:' "$metadata_file" || \
       ! grep -Eq '^[[:space:]]+short_description:' "$metadata_file"; then
    fail "$skill_name: agents/openai.yaml is missing required interface metadata"
  fi

  if ! grep -Fq "skills/$skill_name/README.md" "$repo_root/README.md"; then
    fail "$skill_name: README skill index entry is missing"
  fi
done

sort -u "$repo_skills" -o "$repo_skills"

find "$repo_root" -path "$repo_root/.git" -prune -o -type f -name '*.md' -print | while IFS= read -r markdown_file; do
  grep -Eo '\]\([^)]*\)' "$markdown_file" 2>/dev/null | sed -e 's/^](//' -e 's/)$//' | while IFS= read -r markdown_link; do
    case "$markdown_link" in
      ''|'#'*|http://*|https://*|mailto:*) continue ;;
    esac
    relative_path=${markdown_link%%#*}
    if [ -n "$relative_path" ] && [ ! -e "$(dirname -- "$markdown_file")/$relative_path" ]; then
      printf '%s: %s\n' "${markdown_file#"$repo_root"/}" "$markdown_link" >> "$link_errors"
    fi
  done
done

if [ -s "$link_errors" ]; then
  while IFS= read -r broken_link; do
    fail "broken Markdown link: $broken_link"
  done < "$link_errors"
else
  pass 'SKILL.md metadata and Markdown links'
fi

printf '%s\n' '[User installation]'

if [ ! -d "$user_skills_dir" ]; then
  fail "$user_skills_dir does not exist"
else
  find "$user_skills_dir" -mindepth 1 -maxdepth 1 -type l ! -exec test -e {} \; -print | while IFS= read -r broken_link; do
    printf '%s\n' "$broken_link" >> "$broken_symlinks"
  done

  if [ -s "$broken_symlinks" ]; then
    while IFS= read -r broken_link; do
      fail "broken user skill symlink: $broken_link"
    done < "$broken_symlinks"
  fi

  while IFS= read -r skill_name; do
    installed_path=$user_skills_dir/$skill_name
    expected_path=$repo_root/skills/$skill_name
    if [ ! -L "$installed_path" ]; then
      fail "$skill_name: official user skill symlink is missing"
      continue
    fi

    installed_target=$(CDPATH= cd -- "$installed_path" 2>/dev/null && pwd -P)
    expected_target=$(CDPATH= cd -- "$expected_path" && pwd -P)
    if [ "$installed_target" != "$expected_target" ]; then
      fail "$skill_name: symlink target differs from repository"
    else
      printf '%s\n' "$skill_name" >> "$installed_skills"
    fi
  done < "$repo_skills"

  for installed_md in "$user_skills_dir"/*/SKILL.md; do
    [ -f "$installed_md" ] || continue
    basename -- "$(dirname -- "$installed_md")"
  done | sort -u > "$all_installed_skills"

  comm -13 "$repo_skills" "$all_installed_skills" > "$extra_installed_skills"
  if [ -s "$extra_installed_skills" ]; then
    while IFS= read -r extra_skill; do
      [ -n "$extra_skill" ] && warn "$extra_skill: user-only skill is installed"
    done < "$extra_installed_skills"
  fi

  if [ "$(wc -l < "$installed_skills" | tr -d ' ')" = "$(wc -l < "$repo_skills" | tr -d ' ')" ]; then
    pass 'all repository skills are linked from the official user path'
  fi
fi

printf '%s\n' '[System baseline]'

sed -n '/^[^#[:space:]]/p' "$repo_root/skills/codex-system-skills.txt" | sort -u > "$baseline_skills"
if [ ! -d "$system_skills_dir" ]; then
  warn "$system_skills_dir is unavailable; bundled-skill comparison skipped"
else
  find "$system_skills_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -u > "$actual_system_skills"
  missing_system=$(comm -23 "$baseline_skills" "$actual_system_skills")
  extra_system=$(comm -13 "$baseline_skills" "$actual_system_skills")
  if [ -n "$missing_system" ]; then
    fail "bundled skills missing locally: $(printf '%s' "$missing_system" | tr '\n' ' ')"
  fi
  if [ -n "$extra_system" ]; then
    warn "bundled skills present only locally: $(printf '%s' "$extra_system" | tr '\n' ' ')"
  fi
  if [ -z "$missing_system" ] && [ -z "$extra_system" ]; then
    pass 'bundled-skill baseline matches local installation'
  fi
fi

printf '[Summary] errors=%s warnings=%s\n' "$error_count" "$warning_count"
[ "$error_count" -eq 0 ]
