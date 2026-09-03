# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-YYYYMMDD-<slug>-<sequence>`
- `generated_at`: `YYYY-MM-DDThh:mm:ss+09:00`
- `baseline_version`: `<집계 대상 baseline 버전>`
- `report_status`: `<READY, LIMITED, BLOCKED 중 하나>`
- `comparison_readiness`: `<READY, LIMITED 중 하나>`

## 집계 범위

- `window_start`: `YYYY-MM-DDThh:mm:ss+09:00`
- `window_end`: `YYYY-MM-DDThh:mm:ss+09:00`
- `selection_rule`: `<포함·제외 기준>`
- `aggregation_method`: `<count와 신호 산정 방법>`
- `limitations`: `<비교 한계 또는 NONE>`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `<trace 식별자>` | `YYYY-MM-DDThh:mm:ss+09:00` | `<task_type>` | `minimum`, `extended` 중 하나 | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `<양의 정수>` | `<0 이상의 정수>` | `true`, `false` 중 하나 | `true`, `false` 중 하나 | `INCLUDED`, `EXCLUDED` 중 하나 |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `<0 이상의 정수>`
- `included_trace_count`: `<0 이상의 정수>`
- `excluded_trace_count`: `<0 이상의 정수>`
- `pass_count`: `<0 이상의 정수>`
- `fail_count`: `<0 이상의 정수>`
- `blocked_count`: `<0 이상의 정수>`
- `total_attempt_count`: `<0 이상의 정수>`
- `total_rework_count`: `<0 이상의 정수>`
- `unverified_trace_count`: `<0 이상의 정수>`
- `remaining_risk_trace_count`: `<0 이상의 정수>`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-<REPORT>-01` | `<실패, 검증 누락, 재작업, 승인, 소유권 중 하나>` | `<양의 정수>` | `<쉼표로 구분한 trace 식별자>` | `OPEN`, `RESOLVED`, `INSUFFICIENT_EVIDENCE` 중 하나 | `LOW`, `MEDIUM`, `HIGH` 중 하나 | `<관찰 사실과 현재 상태>` |

## Candidate 판단

- `candidate_recommendation`: `<CREATE, DEFER, NONE 중 하나>`
- `candidate_reason`: `<반복 신호와 재평가 가능성에 근거한 판단>`
- `recommended_evaluation`: `<candidate를 만들 경우 적용할 task·evaluator·비교 방법 또는 NONE>`

## 결론

- `conclusion`: `<집계 결과와 다음 단계>`
