# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260903-report-source-integrity-01`
- `created_at`: `2026-09-03T11:01:00+09:00`
- `baseline_version`: `0.1.0-initial`
- `candidate_status`: `PROMOTED`
- `promoted_at`: `2026-09-03T11:15:01+09:00`
- `promoted_version`: `0.2.0-report-source-integrity`
- `promotion_trace_id`: `tr-20260903-report-source-promotion-01`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260903-harness-bootstrap-01`
- `source_signal_ids`: `SIG-HARNESS-REPORT-SOURCE-01`
- `problem_statement`: `report source 행의 메타데이터가 원본 trace와 달라도 내부 집계만 맞으면 Diagnostics가 정상 report로 통과시킨다.`
- `evidence_summary`: `동일 task·evaluator와 격리 HOME에서 recorded_at, task_type, trace_level만 각각 바꾼 세 fixture가 모두 errors=0으로 잘못 통과했다.`

## 개선안 (`proposed_change`)

- `change_summary`: `report source 행의 식별자와 집계 필드를 원본 trace scalar 값에 대조하고 누락·불일치를 오류로 판정한다.`
- `target_files`: `scripts/doctor.sh, scripts/test-doctor-harness.sh`
- `expected_effect`: `세 불일치 fixture는 모두 실패하고 정상 repository와 기존 전체 회귀 suite는 계속 통과한다.`
- `non_goals`: `자유 서술의 의미 분석, report 자동 생성, trace 내용 변경`
- `rollback_plan`: `scripts/doctor.sh의 report source 대조 호출·함수와 연결 회귀 fixture를 되돌리고 baseline version을 직전 0.1.0-initial로 복원한다.`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `harness-contract`
- `affected_evaluator_ids`: `harness-contract`
- `controlled_inputs`: `같은 repository snapshot, 격리 HOME, 동일 doctor 명령과 source 행 한 필드만 다른 세 fixture`
- `minimum_comparison_pairs`: `3`
- `evaluation_commands`: `각 fixture에서 baseline scripts/doctor.sh와 candidate validate-report-sources.sh를 순서대로 실행하고 종료 코드·진단을 비교한다.`
- `regression_scope`: `정상 repository candidate 검사, scripts/test-doctor-harness.sh 전체 fixture, shell 구문과 git diff whitespace 검사`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `cmp-report-source-recorded-at-01` | `harness-contract` | `harness-contract` | `tr-20260903-report-source-recorded-at-01` | `tr-20260903-report-source-candidate-01` | `IMPROVED` | `baseline은 불일치를 놓쳤고 candidate는 recorded_at 차이를 진단했다.` |
| `cmp-report-source-task-type-01` | `harness-contract` | `harness-contract` | `tr-20260903-report-source-task-type-01` | `tr-20260903-report-source-candidate-01` | `IMPROVED` | `baseline은 불일치를 놓쳤고 candidate는 task_type 차이를 진단했다.` |
| `cmp-report-source-trace-level-01` | `harness-contract` | `harness-contract` | `tr-20260903-report-source-trace-level-01` | `tr-20260903-report-source-candidate-01` | `IMPROVED` | `baseline은 불일치를 놓쳤고 candidate는 trace_level 차이를 진단했다.` |

## 판정

- `evaluation_result`: `IMPROVED`
- `promotion_recommendation`: `PROMOTE`
- `decision_reason`: `동일한 세 fixture에서 baseline은 모두 놓치고 candidate는 모두 탐지했으며 정상 입력과 기존 전체 회귀 suite도 통과해 0.2.0-report-source-integrity로 승격했다.`
- `remaining_risks`: `정적 scalar 대조는 자유 서술의 의미적 동일성까지 보장하지 않는다.`
- `approved_by`: `repository owner`
