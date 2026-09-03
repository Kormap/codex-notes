#!/bin/sh

set -u

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
test_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-notes-doctor-test.XXXXXX") || exit 1
trap 'case "$test_root" in "${TMPDIR:-/tmp}"/codex-notes-doctor-test.*) rm -rf "$test_root" ;; esac' EXIT HUP INT TERM

fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

pass_test() {
  printf '[PASS] %s\n' "$1"
}

new_fixture() {
  fixture_name=$1
  fixture_root=$test_root/$fixture_name
  fixture_repo=$fixture_root/repo
  fixture_home=$fixture_root/home

  mkdir -p "$fixture_repo" "$fixture_home/.agents/skills" "$fixture_home/.codex/skills/.system" || exit 1
  cp -R "$repo_root/." "$fixture_repo" 2>/dev/null || exit 1
  seed_trace_runs

  for fixture_skill in "$fixture_repo"/skills/*/SKILL.md; do
    [ -f "$fixture_skill" ] || continue
    fixture_skill_name=$(basename -- "$(dirname -- "$fixture_skill")")
    ln -s "$fixture_repo/skills/$fixture_skill_name" "$fixture_home/.agents/skills/$fixture_skill_name" || exit 1
  done

  while IFS= read -r fixture_system_skill; do
    case "$fixture_system_skill" in
      ''|'#'*) continue ;;
    esac
    mkdir -p "$fixture_home/.codex/skills/.system/$fixture_system_skill" || exit 1
  done < "$fixture_repo/skills/codex-system-skills.txt"
}

write_trace() {
  trace_id=$1
  recorded_at=$2
  task_type=$3
  trace_level=$4
  final_result=$5
  attempt_count=$6
  rework_count=$7
  has_unverified=$8
  has_remaining_risk=$9
  baseline_version=${10}
  task_reference=${11}
  evaluator_id=${12}
  repeated_trigger=${13}

  case "$has_unverified" in
    true) unverified_value='테스트 fixture에서 의도적으로 미검증 항목을 남긴다.' ;;
    *) unverified_value='NONE' ;;
  esac
  case "$has_remaining_risk" in
    true) remaining_risks_value='테스트 fixture에서 의도적으로 남은 위험을 남긴다.' ;;
    *) remaining_risks_value='NONE' ;;
  esac

  cat > "$fixture_repo/.harness/traces/runs/$trace_id.md" <<EOF
# 최소 Harness Trace

## 메타데이터

- \`schema_version\`: \`1\`
- \`trace_id\`: \`$trace_id\`
- \`recorded_at\`: \`$recorded_at\`
- \`baseline_version\`: \`$baseline_version\`
- \`trace_level\`: \`$trace_level\`
- \`final_result\`: \`$final_result\`

## 작업

- \`task_type\`: \`$task_type\`
- \`task_reference\`: \`$task_reference\`
- \`request_summary\`: \`doctor 회귀 테스트 fixture\`
- \`in_scope\`: \`Harness Diagnostics fixture\`
- \`out_of_scope\`: \`NONE\`

## 성공 조건 (\`success_criteria\`)

- [x] \`SC-01\`: \`fixture trace가 report source 대조에 필요한 필드를 제공한다.\`

## 적용 Skill

- \`applied_skills\`: \`NONE\`

## 변경

- \`changed_files\`: \`NONE\`
- \`change_summary\`: \`fixture trace 생성\`
- \`approval_summary\`: \`NONE\`
- \`external_actions\`: \`NONE\`

## 시도와 재작업

- \`attempt_count\`: \`$attempt_count\`
- \`rework_count\`: \`$rework_count\`
- \`rework_summary\`: \`NONE\`

## 검증 결과 (\`evaluator_results\`)

| 평가자 (\`evaluator_id\`) | 명령 또는 방법 (\`command_or_method\`) | 결과 (\`result\`) | 근거 요약 (\`evidence_summary\`) |
|---|---|---|---|
| \`$evaluator_id\` | \`fixture\` | \`$final_result\` | \`fixture result\` |

## 미검증 항목과 남은 위험

- \`unverified\`: \`$unverified_value\`
- \`remaining_risks\`: \`$remaining_risks_value\`

## 최종 판정

- \`result_reason\`: \`fixture 최종 판정\`
- \`user_report_consistency\`: \`CONSISTENT\`
EOF

  [ "$trace_level" = 'extended' ] || return 0

  cat >> "$fixture_repo/.harness/traces/runs/$trace_id.md" <<EOF

## 확장 메타데이터

- \`trigger_high_risk\`: \`false\`
- \`trigger_repeated_evaluation\`: \`$repeated_trigger\`
- \`trigger_multi_agent\`: \`false\`

## 고위험 근거 (\`high_risk_evidence\`)

### 위험 (\`risks\`)

| 위험 (\`risk\`) | 영향 (\`impact\`) | 통제 (\`control\`) | 잔여 위험 (\`residual_risk\`) |
|---|---|---|---|
| \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` |

### 승인 (\`approvals\`)

| 요청 시각 (\`requested_at\`) | 행동과 정확한 대상 (\`action_target\`) | 결정 (\`decision\`) | 수행 (\`performed\`) | 근거 요약 (\`evidence_summary\`) |
|---|---|---|---|---|
| \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` |

### 외부 행동과 복구 (\`external_actions_recovery\`)

- \`external_action_details\`: \`NOT_APPLICABLE\`
- \`failure_observed\`: \`NOT_APPLICABLE\`
- \`recovery_decision\`: \`NOT_APPLICABLE\`
- \`recovery_result\`: \`NOT_APPLICABLE\`

## 반복 평가 근거 (\`repeated_evaluation_evidence\`)

- \`run_id\`: \`run-02\`
- \`comparison_target\`: \`run-01\`
- \`controlled_inputs\`: \`동일 fixture\`

### 비교 결과 (\`comparison_results\`)

| 평가자 (\`evaluator_id\`) | 이전 결과 (\`previous_result\`) | 현재 결과 (\`current_result\`) | 품질 변화 (\`quality_change\`) | 근거 요약 (\`evidence_summary\`) |
|---|---|---|---|---|
| \`$evaluator_id\` | \`FAIL\` | \`PASS\` | \`IMPROVED\` | \`fixture comparison\` |

- \`rework_cause\`: \`이전 실행 실패\`
- \`comparison_limitations\`: \`NONE\`

## 멀티에이전트 근거 (\`multi_agent_evidence\`)

### 역할 배정과 소유권 (\`agent_assignments\`)

| 에이전트·작업 ID (\`agent_task_id\`) | 역할 (\`role\`) | 배정 범위 (\`assigned_scope\`) | 쓰기 가능 파일 (\`writable_files\`) | 상태 (\`status\`) |
|---|---|---|---|---|
| \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` |

### 위임과 역할 결과 (\`delegations\`)

| 위임자 (\`from\`) | 수임자 (\`to\`) | 계약 요약 (\`contract_summary\`) | 결과 채택 (\`result_adopted\`) | 결과·근거 요약 (\`result_evidence_summary\`) |
|---|---|---|---|---|
| \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` | \`NOT_APPLICABLE\` |

- \`role_separation\`: \`NOT_APPLICABLE\`
- \`ownership_conflicts\`: \`NOT_APPLICABLE\`
- \`escalations\`: \`NOT_APPLICABLE\`

### 통합과 최종 검증 (\`integration_verification\`)

- \`integrated_by\`: \`NOT_APPLICABLE\`
- \`adopted_changes\`: \`NOT_APPLICABLE\`
- \`rejected_or_reworked_results\`: \`NOT_APPLICABLE\`
- \`integration_evaluator\`: \`NOT_APPLICABLE\`
- \`independence_limitations\`: \`NOT_APPLICABLE\`
EOF
}

seed_trace_runs() {
  mkdir -p "$fixture_repo/.harness/traces/runs" || exit 1

  write_trace tr-20260902-trace-contract-01 2026-09-02T21:28:39+09:00 feature minimum PASS 1 2 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract false
  write_trace tr-20260902-task-evaluator-contract-01 2026-09-02T22:02:03+09:00 feature minimum PASS 1 0 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract false
  write_trace tr-20260902-markdown-template-rendering-01 2026-09-02T22:07:44+09:00 bug_fix minimum PASS 1 0 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract false
  write_trace tr-20260902-backend-api-feature-contract-01 2026-09-02T22:12:24+09:00 feature minimum PASS 1 1 true true 0.1.0-initial .harness/tasks/backend-api-feature.md backend-api-feature false
  write_trace tr-20260902-doctor-harness-contract-01 2026-09-02T22:22:51+09:00 behavior_change minimum PASS 1 1 false true 0.1.0-initial .harness/tasks/harness-contract.md current-request false
  write_trace tr-20260903-harness-pilot-01 2026-09-03T09:14:37+09:00 behavior_change extended PASS 3 2 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract true
  write_trace tr-20260903-report-source-recorded-at-01 2026-09-03T10:59:21+09:00 bug_fix extended FAIL 1 0 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract true
  write_trace tr-20260903-report-source-task-type-01 2026-09-03T10:59:22+09:00 bug_fix minimum FAIL 1 0 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract false
  write_trace tr-20260903-report-source-trace-level-01 2026-09-03T10:59:23+09:00 bug_fix minimum FAIL 1 0 true true 0.1.0-initial .harness/tasks/harness-contract.md harness-contract false
  write_trace tr-20260903-report-source-promotion-01 2026-09-03T11:15:00+09:00 behavior_change minimum PASS 1 0 false false 0.2.0-report-source-integrity .harness/candidates/cd-20260903-report-source-integrity-01.md harness-contract false
  write_trace tr-20260903-report-source-candidate-01 2026-09-03T11:10:00+09:00 behavior_change extended PASS 1 0 false false 0.1.0-initial .harness/candidates/cd-20260903-report-source-integrity-01.md harness-contract true
}

run_expect_pass() {
  fixture_label=$1
  fixture_output=$fixture_root/output.txt
  if ! HOME=$fixture_home "$fixture_repo/scripts/doctor.sh" > "$fixture_output" 2>&1; then
    sed -n '1,240p' "$fixture_output" >&2
    fail_test "$fixture_label: doctor unexpectedly failed"
  fi
  pass_test "$fixture_label"
}

run_expect_fail() {
  fixture_label=$1
  shift
  fixture_output=$fixture_root/output.txt
  if HOME=$fixture_home "$fixture_repo/scripts/doctor.sh" > "$fixture_output" 2>&1; then
    sed -n '1,240p' "$fixture_output" >&2
    fail_test "$fixture_label: doctor unexpectedly passed"
  fi
  for expected_text in "$@"; do
    if ! grep -Fq "$expected_text" "$fixture_output"; then
      sed -n '1,240p' "$fixture_output" >&2
      fail_test "$fixture_label: missing diagnostic: $expected_text"
    fi
  done
  pass_test "$fixture_label"
}

new_fixture valid
run_expect_pass 'valid repository fixture'

new_fixture pruned-traces
mv "$fixture_repo/.harness/traces/runs" "$fixture_repo/.harness/traces/pruned-runs" || exit 1
mkdir -p "$fixture_repo/.harness/traces/runs" || exit 1
run_expect_pass 'durable reports and promoted candidates survive trace retention cleanup'

awk '
  { print }
  END {
    print ""
    print "문서 설명에서 `AC-BEBUG-01`과 `AC-BEBUG-99`를 다시 언급해도 성공 조건 행으로 간주하지 않는다."
  }
' "$fixture_repo/.harness/tasks/backend-bugfix.md" > "$fixture_repo/.harness/tasks/backend-bugfix.md.tmp" || exit 1
mv "$fixture_repo/.harness/tasks/backend-bugfix.md.tmp" "$fixture_repo/.harness/tasks/backend-bugfix.md" || exit 1
run_expect_pass 'acceptance IDs outside the success section are ignored'

new_fixture template-index-errors
sed 's/YYYY-MM-DDThh:mm:ss+09:00/YYYY-MM-DDThh:mm:ssZ/' \
  "$fixture_repo/.harness/traces/templates/minimum-trace.md" > "$fixture_root/minimum-trace.md" || exit 1
mv "$fixture_root/minimum-trace.md" "$fixture_repo/.harness/traces/templates/minimum-trace.md" || exit 1
sed 's/결과 (`result`)/결과 (`outcome`)/' \
  "$fixture_repo/.harness/traces/templates/minimum-trace.md" > "$fixture_root/minimum-trace.md" || exit 1
mv "$fixture_root/minimum-trace.md" "$fixture_repo/.harness/traces/templates/minimum-trace.md" || exit 1
sed 's/품질 변화 (`quality_change`)/품질 변화 (`quality_delta`)/' \
  "$fixture_repo/.harness/traces/templates/extended-trace.md" > "$fixture_root/extended-trace.md" || exit 1
mv "$fixture_root/extended-trace.md" "$fixture_repo/.harness/traces/templates/extended-trace.md" || exit 1
awk '
  index($0, "[backend-api-feature.md](backend-api-feature.md)") { next }
  { print }
' "$fixture_repo/.harness/tasks/README.md" > "$fixture_root/tasks-README.md" || exit 1
mv "$fixture_root/tasks-README.md" "$fixture_repo/.harness/tasks/README.md" || exit 1
sed 's#](.harness/roles/README.md)#](.harness/roles/index.md)#' \
  "$fixture_repo/README.md" > "$fixture_root/README.md" || exit 1
mv "$fixture_root/README.md" "$fixture_repo/README.md" || exit 1
run_expect_fail 'trace template and Harness indexes are validated' \
  '.harness/traces/templates/minimum-trace.md: recorded_at template must use the +09:00 timezone offset' \
  '.harness/traces/templates/minimum-trace.md: evaluator_results header does not match the trace contract' \
  '.harness/traces/templates/extended-trace.md: comparison_results header does not match the extended trace contract' \
  '.harness/tasks/README.md: missing index link for .harness/tasks/backend-api-feature.md: backend-api-feature.md' \
  'README.md: missing index link for .harness/roles/README.md: .harness/roles/README.md'

new_fixture missing-file
mv "$fixture_repo/.harness/roles/verifier.md" "$fixture_repo/.harness/roles/verifier.md.missing" || exit 1
run_expect_fail 'required Harness file is diagnosed' '.harness/roles/verifier.md is missing'

new_fixture baseline-history-errors
sed \
  -e 's/- Version: `0.3.0-reference-lifecycle`/- Version: `9.9.9-unknown`/' \
  -e 's/| `0.2.0-report-source-integrity` | 2026-09-03 | 이전 |/| `0.2.0-report-source-integrity` | 2026-09-03 | 활성 |/' \
  "$fixture_repo/.harness/baseline/version.md" > "$fixture_root/version.md" || exit 1
mv "$fixture_root/version.md" "$fixture_repo/.harness/baseline/version.md" || exit 1
run_expect_fail 'current baseline and active version history are cross-checked' \
  '.harness/baseline/version.md: version history must contain exactly one 활성 row' \
  '.harness/baseline/version.md: current Version is missing from version history: 9.9.9-unknown'

new_fixture candidate-implementation-permission
chmod -x "$fixture_repo/.harness/candidates/implementations/cd-20260903-report-source-integrity-01/validate-report-sources.sh" || exit 1
run_expect_fail 'candidate implementation scripts must be executable' \
  '.harness/candidates/implementations/cd-20260903-report-source-integrity-01/validate-report-sources.sh is not executable'

new_fixture mapping-errors
awk '
  /^\| `EV-BEBUG-06` / { next }
  { print }
  /^\| `EV-BEBUG-01` / {
    print "| `EV-BEBUG-01` | `AC-BEBUG-99` | `OPTIONAL` |  |"
  }
' "$fixture_repo/.harness/evaluators/backend-bugfix.md" > "$fixture_repo/.harness/evaluators/backend-bugfix.md.tmp" || exit 1
mv "$fixture_repo/.harness/evaluators/backend-bugfix.md.tmp" "$fixture_repo/.harness/evaluators/backend-bugfix.md" || exit 1
run_expect_fail 'all evaluator mapping rows are validated' \
  'duplicate evaluation check_id: EV-BEBUG-01' \
  'invalid requirement: `OPTIONAL`' \
  'empty or placeholder method' \
  'unknown acceptance criterion: AC-BEBUG-99' \
  'acceptance criterion is not connected from evaluation mapping: AC-BEBUG-06'

new_fixture invalid-result
awk '
  /^\| `current-request` / {
    sub(/\| `PASS` \|/, "| `SKIPPED` |")
  }
  { print }
' "$fixture_repo/.harness/traces/runs/tr-20260902-doctor-harness-contract-01.md" > "$fixture_repo/.harness/traces/runs/trace.tmp" || exit 1
mv "$fixture_repo/.harness/traces/runs/trace.tmp" "$fixture_repo/.harness/traces/runs/tr-20260902-doctor-harness-contract-01.md" || exit 1
run_expect_fail 'invalid evaluator result enum is diagnosed' 'has invalid result: `SKIPPED`'

new_fixture contradictory-result
sed 's/- \[x\] `SC-01`:/- [ ] `SC-01`:/' \
  "$fixture_repo/.harness/traces/runs/tr-20260902-doctor-harness-contract-01.md" > "$fixture_repo/.harness/traces/runs/trace.tmp" || exit 1
mv "$fixture_repo/.harness/traces/runs/trace.tmp" "$fixture_repo/.harness/traces/runs/tr-20260902-doctor-harness-contract-01.md" || exit 1
run_expect_fail 'contradictory final result is diagnosed' \
  'final_result PASS contradicts evaluator results and success criteria; expected FAIL'

new_fixture comparison-history
cat > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" <<'EOF'
# 확장 Harness Trace

## 메타데이터

- `schema_version`: `1`
- `trace_id`: `tr-20260902-comparison-history-01`
- `recorded_at`: `2026-09-02T23:00:00+09:00`
- `baseline_version`: `0.1.0-initial`
- `trace_level`: `extended`
- `final_result`: `PASS`

## 작업

- `task_type`: `repeated_work`
- `task_reference`: `doctor comparison history regression fixture`
- `request_summary`: `과거 비교 결과와 현재 evaluator 결과의 범위를 구분한다.`
- `in_scope`: `trace parser`
- `out_of_scope`: `NONE`

## 성공 조건 (`success_criteria`)

- [x] `SC-01`: `현재 evaluator 결과만 최종 판정에 반영한다.`

## 적용 Skill

- `applied_skills`: `NONE`

## 변경

- `changed_files`: `NONE`
- `change_summary`: `회귀 fixture`
- `approval_summary`: `NONE`
- `external_actions`: `NONE`

## 시도와 재작업

- `attempt_count`: `1`
- `rework_count`: `0`
- `rework_summary`: `NONE`

## 검증 결과 (`evaluator_results`)

| 평가자 (`evaluator_id`) | 명령 또는 방법 (`command_or_method`) | 결과 (`result`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|
| `trace-result-scope` | `doctor trace parser` | `PASS` | `현재 결과 통과` |

## 미검증 항목과 남은 위험

- `unverified`: `NONE`
- `remaining_risks`: `NONE`

## 최종 판정

- `result_reason`: `현재 evaluator와 성공 조건이 모두 통과했다.`
- `user_report_consistency`: `CONSISTENT`

## 확장 메타데이터

- `trigger_high_risk`: `false`
- `trigger_repeated_evaluation`: `true`
- `trigger_multi_agent`: `false`

## 고위험 근거 (`high_risk_evidence`)

### 위험 (`risks`)

| 위험 (`risk`) | 영향 (`impact`) | 통제 (`control`) | 잔여 위험 (`residual_risk`) |
|---|---|---|---|
| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |

### 승인 (`approvals`)

| 요청 시각 (`requested_at`) | 행동과 정확한 대상 (`action_target`) | 결정 (`decision`) | 수행 (`performed`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|
| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |

### 외부 행동과 복구 (`external_actions_recovery`)

- `external_action_details`: `NOT_APPLICABLE`
- `failure_observed`: `NOT_APPLICABLE`
- `recovery_decision`: `NOT_APPLICABLE`
- `recovery_result`: `NOT_APPLICABLE`

## 반복 평가 근거 (`repeated_evaluation_evidence`)

- `run_id`: `run-02`
- `comparison_target`: `run-01`
- `controlled_inputs`: `동일 fixture`

### 비교 결과 (`comparison_results`)

| 평가자 (`evaluator_id`) | 이전 결과 (`previous_result`) | 현재 결과 (`current_result`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|
| `trace-result-scope` | `FAIL` | `PASS` | `IMPROVED` | `이전 실패를 수정했다.` |

- `rework_cause`: `이전 실행 실패`
- `comparison_limitations`: `NONE`

## 멀티에이전트 근거 (`multi_agent_evidence`)

### 역할 배정과 소유권 (`agent_assignments`)

| 에이전트·작업 ID (`agent_task_id`) | 역할 (`role`) | 배정 범위 (`assigned_scope`) | 쓰기 가능 파일 (`writable_files`) | 상태 (`status`) |
|---|---|---|---|---|
| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |

### 위임과 역할 결과 (`delegations`)

| 위임자 (`from`) | 수임자 (`to`) | 계약 요약 (`contract_summary`) | 결과 채택 (`result_adopted`) | 결과·근거 요약 (`result_evidence_summary`) |
|---|---|---|---|---|
| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |

- `role_separation`: `NOT_APPLICABLE`
- `ownership_conflicts`: `NOT_APPLICABLE`
- `escalations`: `NOT_APPLICABLE`

### 통합과 최종 검증 (`integration_verification`)

- `integrated_by`: `NOT_APPLICABLE`
- `adopted_changes`: `NOT_APPLICABLE`
- `rejected_or_reworked_results`: `NOT_APPLICABLE`
- `integration_evaluator`: `NOT_APPLICABLE`
- `independence_limitations`: `NOT_APPLICABLE`
EOF
run_expect_pass 'comparison history FAIL does not affect current final result'

cp "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" "$fixture_root/valid-extended.md" || exit 1

sed 's/- `recorded_at`: `2026-09-02T23:00:00+09:00`/- `recorded_at`: `2026-09-02T14:00:00Z`/' \
  "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'recorded_at rejects non-Korean timezone offsets' \
  'recorded_at must be ISO 8601 with the +09:00 timezone offset'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
awk '
  $0 == "| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |" && !removed {
    removed = 1
    next
  }
  { print }
' "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'missing extended table data is diagnosed' \
  'risks must contain exactly one data row when its trigger is false'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
sed 's/| `trace-result-scope` | `FAIL` | `PASS` | `IMPROVED` |/| `trace-result-scope` | `FAIL` | `SKIPPED` | `IMPROVED` |/' \
  "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'invalid extended table enum is diagnosed' \
  'comparison_results row 1 has invalid current_result: SKIPPED'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
awk '
  $0 == "### 역할 배정과 소유권 (`agent_assignments`)" {
    in_assignments = 1
  }
  in_assignments && /^### / && $0 != "### 역할 배정과 소유권 (`agent_assignments`)" {
    in_assignments = 0
  }
  in_assignments && /^\| `NOT_APPLICABLE` / {
    sub(/`NOT_APPLICABLE`/, "`NONE`")
  }
  { print }
' "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'false-trigger table sentinel violation is diagnosed' \
  'agent_assignments false-trigger row must contain only NOT_APPLICABLE'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
awk '
  /^- `trigger_high_risk`:/ { sub(/`false`/, "`true`") }
  /^- `(external_action_details|failure_observed|recovery_decision|recovery_result)`:/ {
    sub(/`NOT_APPLICABLE`/, "`NONE`")
  }
  $0 == "| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |" {
    print "| `risk` | `impact` | `control` | `NONE` |"
    next
  }
  $0 == "| `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` | `NOT_APPLICABLE` |" && !approval_replaced {
    print "| `2026-09-02T23:00:00+09:00` | `action` | `DENIED` | `true` | `evidence` |"
    print "| `2026-09-02T23:01:00+09:00` | `action` | `REJECTED` | `yes` | `evidence` |"
    approval_replaced = 1
    next
  }
  { print }
' "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'approval decision and performed state are cross-checked' \
  'has invalid decision: REJECTED' \
  'has invalid performed value: yes' \
  'requires performed=false for DENIED' \
  'requires APPROVED when performed=true'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
awk '
  /^- `trigger_multi_agent`:/ { sub(/`false`/, "`true`") }
  /^- `(role_separation|ownership_conflicts|escalations|integrated_by|adopted_changes|rejected_or_reworked_results|integration_evaluator|independence_limitations)`:/ {
    sub(/`NOT_APPLICABLE`/, "`NONE`")
  }
  /^### / {
    in_assignments = ($0 == "### 역할 배정과 소유권 (`agent_assignments`)")
    in_delegations = ($0 == "### 위임과 역할 결과 (`delegations`)")
  }
  in_assignments && /^\| `NOT_APPLICABLE` / {
    print "| `agent-1` | `Builder` | `scope` | `NONE` | `DONE` |"
    next
  }
  in_delegations && /^\| `NOT_APPLICABLE` / {
    print "| `Lead` | `agent-1` | `contract` | `ACCEPTED` | `evidence` |"
    next
  }
  { print }
' "$fixture_root/valid-extended.md" > "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'multi-agent table enums are validated' \
  'agent_assignments row 1 has invalid role: Builder' \
  'agent_assignments row 1 has invalid status: DONE' \
  'delegations row 1 has invalid result_adopted: ACCEPTED'

cp "$fixture_root/valid-extended.md" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
sed 's/- `external_action_details`: `NOT_APPLICABLE`/- `external_action_details`: `NONE`/' \
  "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" > "$fixture_repo/.harness/traces/runs/trace.tmp" || exit 1
mv "$fixture_repo/.harness/traces/runs/trace.tmp" "$fixture_repo/.harness/traces/runs/tr-20260902-comparison-history-01.md" || exit 1
run_expect_fail 'false extended trigger requires NOT_APPLICABLE scalars' \
  'external_action_details must be NOT_APPLICABLE when its trigger is false'

new_fixture report-contract-errors
sed 's/결과 (`final_result`)/결과 (`result`)/' \
  "$fixture_repo/.harness/reports/templates/report-template.md" > "$fixture_root/report-template.md" || exit 1
mv "$fixture_root/report-template.md" "$fixture_repo/.harness/reports/templates/report-template.md" || exit 1
sed \
  -e 's/- `report_status`: `READY`/- `report_status`: `UNKNOWN`/' \
  -e 's/- `source_trace_count`: `9`/- `source_trace_count`: `8`/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
awk '
  /^\| `tr-/ && !changed {
    sub(/\| `INCLUDED` \|$/, "| `SKIPPED` |")
    changed = 1
  }
  { print }
' "$fixture_root/report.md" > "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
run_expect_fail 'report template, enums and aggregate counts are validated' \
  '.harness/reports/templates/report-template.md: source_traces header does not match the report contract' \
  '.harness/reports/rp-20260903-harness-bootstrap-01.md: invalid report_status: UNKNOWN' \
  '.harness/reports/rp-20260903-harness-bootstrap-01.md: source_traces row 1 has invalid inclusion: SKIPPED' \
  '.harness/reports/rp-20260903-harness-bootstrap-01.md: source_trace_count does not match source_traces: expected 9, found 8'

new_fixture report-source-reference-errors
sed \
  -e '/tr-20260902-trace-contract-01/s/2026-09-02T21:28:39+09:00/2026-09-02T21:28:40+09:00/' \
  -e '/tr-20260902-task-evaluator-contract-01/s/| `feature` |/| `bug_fix` |/' \
  -e '/tr-20260902-markdown-template-rendering-01/s/| `minimum` |/| `extended` |/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
mv "$fixture_root/report.md" "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
run_expect_fail 'report source rows are cross-checked against referenced traces' \
  'source trace tr-20260902-trace-contract-01 recorded_at differs from trace: report=2026-09-02T21:28:40+09:00 trace=2026-09-02T21:28:39+09:00' \
  'source trace tr-20260902-task-evaluator-contract-01 task_type differs from trace: report=bug_fix trace=feature' \
  'source trace tr-20260902-markdown-template-rendering-01 trace_level differs from trace: report=extended trace=minimum'

new_fixture report-signal-reference-errors
sed \
  -e '/SIG-HARNESS-BOOTSTRAP-01/s/| `4` |/| `5` |/' \
  -e '/SIG-HARNESS-BOOTSTRAP-02/s/tr-20260903-harness-pilot-01/tr-20260902-trace-contract-01/' \
  -e '/SIG-HARNESS-REPORT-SOURCE-01/s/tr-20260903-report-source-trace-level-01/tr-20991231-missing-source-01/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
mv "$fixture_root/report.md" "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
run_expect_fail 'report signal evidence references and counts are validated' \
  'signals row 1 occurrence_count does not match evidence_trace_ids: expected 4, found 5' \
  'signals row 2 has duplicate evidence_trace_id: tr-20260902-trace-contract-01' \
  'signals row 4 references trace outside source inventory: tr-20991231-missing-source-01'

new_fixture baseline-version-reference-errors
sed 's/- `baseline_version`: `0.1.0-initial`/- `baseline_version`: `9.9.9-unknown`/' \
  "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" > "$fixture_root/candidate.md" || exit 1
mv "$fixture_root/candidate.md" "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" || exit 1
sed 's/- `baseline_version`: `0.1.0-initial`/- `baseline_version`: `9.9.9-unknown`/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
mv "$fixture_root/report.md" "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
sed 's/- `baseline_version`: `0.2.0-report-source-integrity`/- `baseline_version`: `9.9.9-unknown`/' \
  "$fixture_repo/.harness/traces/runs/tr-20260903-report-source-promotion-01.md" > "$fixture_root/trace.md" || exit 1
mv "$fixture_root/trace.md" "$fixture_repo/.harness/traces/runs/tr-20260903-report-source-promotion-01.md" || exit 1
run_expect_fail 'trace report and candidate baseline_version must reference version history' \
  '.harness/traces/runs/tr-20260903-report-source-promotion-01.md: unknown baseline_version: 9.9.9-unknown' \
  '.harness/reports/rp-20260903-harness-bootstrap-01.md: unknown baseline_version: 9.9.9-unknown' \
  '.harness/candidates/cd-20260903-report-source-integrity-01.md: unknown baseline_version: 9.9.9-unknown'

new_fixture promoted-candidate-metadata-errors
sed \
  -e 's/- `promoted_at`: `2026-09-03T11:15:01+09:00`/- `promoted_at`: `2026-09-03T02:15:01Z`/' \
  -e 's/- `promoted_version`: `0.2.0-report-source-integrity`/- `promoted_version`: `9.9.9-unknown`/' \
  -e 's/- `promotion_trace_id`: `tr-20260903-report-source-promotion-01`/- `promotion_trace_id`: `tr-20991231-missing-promotion-01`/' \
  "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" > "$fixture_root/candidate.md" || exit 1
mv "$fixture_root/candidate.md" "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" || exit 1
run_expect_fail 'PROMOTED candidate metadata is validated' \
  'PROMOTED requires promoted_at with the +09:00 timezone offset' \
  'PROMOTED requires a known promoted_version: 9.9.9-unknown' \
  'promotion_trace_id is not recorded in baseline history: tr-20991231-missing-promotion-01'

new_fixture candidate-trace-reference-errors
sed \
  -e 's/- `candidate_status`: `PROMOTED`/- `candidate_status`: `ACCEPTED`/' \
  -e 's/- `promoted_at`: `2026-09-03T11:15:01+09:00`/- `promoted_at`: `NOT_APPLICABLE`/' \
  -e 's/- `promoted_version`: `0.2.0-report-source-integrity`/- `promoted_version`: `NOT_APPLICABLE`/' \
  -e 's/- `promotion_trace_id`: `tr-20260903-report-source-promotion-01`/- `promotion_trace_id`: `NOT_APPLICABLE`/' \
  -e 's/tr-20260903-report-source-candidate-01/tr-20991231-missing-candidate-01/g' \
  "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" > "$fixture_root/candidate.md" || exit 1
mv "$fixture_root/candidate.md" "$fixture_repo/.harness/candidates/cd-20260903-report-source-integrity-01.md" || exit 1
run_expect_fail 'accepted candidate comparison traces must exist' \
  'candidate trace is missing: tr-20991231-missing-candidate-01'

new_fixture candidate-trace-contract-errors
sed \
  -e 's/- `trace_level`: `extended`/- `trace_level`: `minimum`/' \
  -e 's/- `trigger_repeated_evaluation`: `true`/- `trigger_repeated_evaluation`: `false`/' \
  "$fixture_repo/.harness/traces/runs/tr-20260903-report-source-candidate-01.md" > "$fixture_root/trace.md" || exit 1
mv "$fixture_root/trace.md" "$fixture_repo/.harness/traces/runs/tr-20260903-report-source-candidate-01.md" || exit 1
run_expect_fail 'candidate comparison trace contract is validated' \
  'candidate trace must be extended: tr-20260903-report-source-candidate-01' \
  'candidate trace must enable repeated evaluation: tr-20260903-report-source-candidate-01'

new_fixture candidate-contract-errors
sed 's/품질 변화 (`quality_change`)/품질 변화 (`quality_delta`)/' \
  "$fixture_repo/.harness/candidates/templates/candidate-template.md" > "$fixture_root/candidate-template.md" || exit 1
mv "$fixture_root/candidate-template.md" "$fixture_repo/.harness/candidates/templates/candidate-template.md" || exit 1
sed \
  -e 's/- `candidate_recommendation`: `CREATE`/- `candidate_recommendation`: `DEFER`/' \
  -e 's/- `comparison_readiness`: `READY`/- `comparison_readiness`: `LIMITED`/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
mv "$fixture_root/report.md" "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
cat > "$fixture_repo/.harness/candidates/cd-20260903-diagnostics-01.md" <<'EOF'
# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260903-diagnostics-01`
- `created_at`: `2026-09-03T12:00:00+09:00`
- `baseline_version`: `0.1.0-initial`
- `candidate_status`: `UNKNOWN`
- `promoted_at`: `NOT_APPLICABLE`
- `promoted_version`: `NOT_APPLICABLE`
- `promotion_trace_id`: `NOT_APPLICABLE`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260903-harness-bootstrap-01`
- `source_signal_ids`: `SIG-HARNESS-BOOTSTRAP-03`
- `problem_statement`: `교차환경 검증 누락`
- `evidence_summary`: `source report의 OPEN 신호`

## 개선안 (`proposed_change`)

- `change_summary`: `교차환경 검증 추가`
- `target_files`: `scripts/test-doctor-harness.sh`
- `expected_effect`: `지원 셸에서 동일 결과 확인`
- `non_goals`: `NONE`
- `rollback_plan`: `candidate 변경 제거`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `backend-bugfix`
- `affected_evaluator_ids`: `missing-evaluator`
- `controlled_inputs`: `동일 fixture와 셸`
- `minimum_comparison_pairs`: `1`
- `evaluation_commands`: `./scripts/test-doctor-harness.sh`
- `regression_scope`: `기존 Harness fixture`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `BROKEN` | `NOT_EVALUATED` |

## 판정

- `evaluation_result`: `PENDING`
- `promotion_recommendation`: `PENDING`
- `decision_reason`: `평가 전`
- `remaining_risks`: `교차환경 미검증`
- `approved_by`: `PENDING`
EOF
run_expect_fail 'candidate template, source, references and state are validated' \
  '.harness/candidates/templates/candidate-template.md: comparison_results header does not match the candidate contract' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: invalid candidate_status: UNKNOWN' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: source report must have candidate_recommendation CREATE: rp-20260903-harness-bootstrap-01' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: source report must have comparison_readiness READY: rp-20260903-harness-bootstrap-01' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: affected_evaluator_ids must include backend-bugfix for task backend-bugfix' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: affected evaluator is missing or invalid: missing-evaluator' \
  '.harness/candidates/cd-20260903-diagnostics-01.md: NOT_EVALUATED comparison row must use the sentinel in every column'

cp "$repo_root/.harness/candidates/templates/candidate-template.md" \
  "$fixture_repo/.harness/candidates/templates/candidate-template.md" || exit 1
sed \
  -e 's/- `candidate_recommendation`: `DEFER`/- `candidate_recommendation`: `CREATE`/' \
  -e 's/- `comparison_readiness`: `LIMITED`/- `comparison_readiness`: `READY`/' \
  "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" > "$fixture_root/report.md" || exit 1
mv "$fixture_root/report.md" "$fixture_repo/.harness/reports/rp-20260903-harness-bootstrap-01.md" || exit 1
sed \
  -e 's/- `candidate_status`: `UNKNOWN`/- `candidate_status`: `READY`/' \
  -e 's/- `affected_evaluator_ids`: `missing-evaluator`/- `affected_evaluator_ids`: `backend-bugfix`/' \
  -e 's/| `NOT_EVALUATED` | `BROKEN` | `NOT_EVALUATED` |/| `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` |/' \
  "$fixture_repo/.harness/candidates/cd-20260903-diagnostics-01.md" > "$fixture_root/candidate.md" || exit 1
mv "$fixture_root/candidate.md" "$fixture_repo/.harness/candidates/cd-20260903-diagnostics-01.md" || exit 1
printf '\n[current candidate](cd-20260903-diagnostics-01.md)\n' >> \
  "$fixture_repo/.harness/candidates/README.md" || exit 1
run_expect_pass 'valid unevaluated candidate fixture'

home_output=$test_root/home-unset.txt
if (unset HOME; "$repo_root/scripts/doctor.sh") > "$home_output" 2>&1; then
  fail_test 'unset HOME unexpectedly passed'
fi
grep -Fq 'HOME must be set to inspect installed skills' "$home_output" || \
  fail_test 'unset HOME did not produce the explicit diagnostic'
pass_test 'unset HOME is diagnosed explicitly'

printf '%s\n' '[PASS] doctor Harness regression fixtures'
