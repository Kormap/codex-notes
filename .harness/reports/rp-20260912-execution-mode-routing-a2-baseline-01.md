# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260912-execution-mode-routing-a2-baseline-01`
- `generated_at`: `2026-09-12T10:54:00+09:00`
- `baseline_version`: `0.5.0-domain-skill-routing`
- `report_status`: `READY`
- `comparison_readiness`: `READY`

## 집계 범위

- `window_start`: `2026-09-12T10:20:01+09:00`
- `window_end`: `2026-09-12T10:20:05+09:00`
- `selection_rule`: `수정된 동일 validator와 고정 fixture·prompt·schema·config·모델·sandbox·collaboration 조건으로 재실행한 SCN-01부터 SCN-05 baseline trace를 포함한다.`
- `aggregation_method`: `EV-ROUTING-01부터 EV-ROUTING-05와 최종 결과를 그대로 집계하고 반복된 gate·decision·fallback 불일치를 하나의 실행 모드 라우팅 신호로 묶었다.`
- `limitations`: `모델 baseline 실행은 상위 delegation 제한에 따라 fallback할 수 있으며 실제 MULTI 품질은 별도 A2 보강 trace에서 확인한다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260912-execution-mode-routing-a2-baseline-01` | `2026-09-12T10:20:01+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-a2-baseline-02` | `2026-09-12T10:20:02+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `false` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-a2-baseline-03` | `2026-09-12T10:20:03+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-a2-baseline-04` | `2026-09-12T10:20:04+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `false` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-a2-baseline-05` | `2026-09-12T10:20:05+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `false` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `5`
- `included_trace_count`: `5`
- `excluded_trace_count`: `0`
- `pass_count`: `0`
- `fail_count`: `5`
- `blocked_count`: `0`
- `total_attempt_count`: `5`
- `total_rework_count`: `0`
- `unverified_trace_count`: `1`
- `remaining_risk_trace_count`: `2`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-EXECUTION-MODE-ROUTING-A2-01` | `검증 누락` | `5` | `tr-20260912-execution-mode-routing-a2-baseline-01, tr-20260912-execution-mode-routing-a2-baseline-02, tr-20260912-execution-mode-routing-a2-baseline-03, tr-20260912-execution-mode-routing-a2-baseline-04, tr-20260912-execution-mode-routing-a2-baseline-05` | `OPEN` | `HIGH` | `수정 validator에서도 다섯 baseline 입력이 gate, decision, fallback 또는 결과 계약 중 하나 이상 FAIL해 기존 라우팅 신호가 재현됐다.` |

## Candidate 판단

- `candidate_recommendation`: `CREATE`
- `candidate_reason`: `다섯 비교 가능한 baseline trace가 동일 조건에서 FAIL했고 Candidate A Skill snapshot을 수정하지 않은 A2 재평가 방법과 corrected validator가 고정됐다.`
- `recommended_evaluation`: `Candidate A Skill snapshot을 A2로 격리해 동일 다섯 입력에 수정된 validator를 적용하고 SCN-01·03·05 실제 MULTI를 보강한다.`

## 결론

- `conclusion`: `READY/CREATE/OPEN을 충족해 Candidate A2 비교의 source report로 사용한다. Candidate A의 기존 terminal 기록이나 baseline version은 변경하지 않는다.`
