# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260903-harness-bootstrap-01`
- `generated_at`: `2026-09-03T10:59:24+09:00`
- `baseline_version`: `0.1.0-initial`
- `report_status`: `READY`
- `comparison_readiness`: `READY`

## 집계 범위

- `window_start`: `2026-09-02T21:28:39+09:00`
- `window_end`: `2026-09-03T10:59:23+09:00`
- `selection_rule`: `baseline 0.1.0-initial의 Harness 구성 trace 6건과 동일 task·evaluator로 report source 참조 정합성을 통제 실행한 trace 3건을 포함한다.`
- `aggregation_method`: `source inventory의 final_result, attempt_count, rework_count와 NONE 여부를 건수로 집계하고 반복 서술은 현재 해소 여부와 함께 검토한다.`
- `limitations`: `전체 9건은 하나의 동질 표본이 아니지만 report source 참조 정합성 3건은 같은 task·evaluator·환경에서 단일 입력 필드만 바꾼 통제 표본이다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260902-trace-contract-01` | `2026-09-02T21:28:39+09:00` | `feature` | `minimum` | `PASS` | `1` | `2` | `true` | `true` | `INCLUDED` |
| `tr-20260902-task-evaluator-contract-01` | `2026-09-02T22:02:03+09:00` | `feature` | `minimum` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260902-markdown-template-rendering-01` | `2026-09-02T22:07:44+09:00` | `bug_fix` | `minimum` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260902-backend-api-feature-contract-01` | `2026-09-02T22:12:24+09:00` | `feature` | `minimum` | `PASS` | `1` | `1` | `true` | `true` | `INCLUDED` |
| `tr-20260902-doctor-harness-contract-01` | `2026-09-02T22:22:51+09:00` | `behavior_change` | `minimum` | `PASS` | `1` | `1` | `false` | `true` | `INCLUDED` |
| `tr-20260903-harness-pilot-01` | `2026-09-03T09:14:37+09:00` | `behavior_change` | `extended` | `PASS` | `3` | `2` | `true` | `true` | `INCLUDED` |
| `tr-20260903-report-source-recorded-at-01` | `2026-09-03T10:59:21+09:00` | `bug_fix` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260903-report-source-task-type-01` | `2026-09-03T10:59:22+09:00` | `bug_fix` | `minimum` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260903-report-source-trace-level-01` | `2026-09-03T10:59:23+09:00` | `bug_fix` | `minimum` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `9`
- `included_trace_count`: `9`
- `excluded_trace_count`: `0`
- `pass_count`: `6`
- `fail_count`: `3`
- `blocked_count`: `0`
- `total_attempt_count`: `11`
- `total_rework_count`: `6`
- `unverified_trace_count`: `8`
- `remaining_risk_trace_count`: `9`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-HARNESS-BOOTSTRAP-01` | `검증 누락` | `4` | `tr-20260902-trace-contract-01, tr-20260902-task-evaluator-contract-01, tr-20260902-markdown-template-rendering-01, tr-20260902-backend-api-feature-contract-01` | `RESOLVED` | `MEDIUM` | `초기 작업에서 반복된 doctor Harness 검사 누락은 doctor 계약과 시범 trace에서 회귀 fixture까지 추가되어 현재 해소됐다.` |
| `SIG-HARNESS-BOOTSTRAP-02` | `재작업` | `2` | `tr-20260902-trace-contract-01, tr-20260903-harness-pilot-01` | `INSUFFICIENT_EVIDENCE` | `LOW` | `두 작업에서 각각 2회 재작업이 있었지만 서로 다른 계약 구축 작업이라 공통 원인을 확정할 수 없다.` |
| `SIG-HARNESS-BOOTSTRAP-03` | `검증 누락` | `1` | `tr-20260903-harness-pilot-01` | `OPEN` | `LOW` | `Linux 계열 /bin/sh 교차환경 검증은 아직 수행되지 않았다.` |
| `SIG-HARNESS-REPORT-SOURCE-01` | `참조 정합성` | `3` | `tr-20260903-report-source-recorded-at-01, tr-20260903-report-source-task-type-01, tr-20260903-report-source-trace-level-01` | `OPEN` | `HIGH` | `report source 행이 원본 trace와 다른 값을 가져도 내부 집계만 맞으면 Diagnostics가 통과한다.` |

## Candidate 판단

- `candidate_recommendation`: `CREATE`
- `candidate_reason`: `동일 task·evaluator의 3개 통제 입력에서 report source 행과 원본 trace의 메타데이터 불일치를 모두 놓쳤고, 잘못된 집계 근거가 정상 report로 통과하는 반복 결함이 확인됐다.`
- `recommended_evaluation`: `recorded_at, task_type, trace_level 불일치 fixture를 baseline과 candidate에 동일하게 적용해 candidate만 세 입력을 탐지하고 기존 전체 회귀가 유지되는지 비교한다.`

## 결론

- `conclusion`: `report source 참조 정합성 결함은 비교 가능한 3건에서 반복되어 candidate 생성 조건을 충족하며, baseline 승격은 candidate 반복 비교와 사용자 승인 후에만 진행한다.`
