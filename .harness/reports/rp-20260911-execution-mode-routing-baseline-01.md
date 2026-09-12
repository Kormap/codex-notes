# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260911-execution-mode-routing-baseline-01`
- `generated_at`: `2026-09-11T23:45:00+09:00`
- `baseline_version`: `0.5.0-domain-skill-routing`
- `report_status`: `READY`
- `comparison_readiness`: `LIMITED`

## 집계 범위

- `window_start`: `2026-09-11T23:40:00+09:00`
- `window_end`: `2026-09-11T23:44:00+09:00`
- `selection_rule`: `execution-mode-routing-current-request-v1의 SCN-01부터 SCN-05까지 활성 baseline 실행 preflight trace를 모두 포함한다.`
- `aggregation_method`: `각 시나리오의 EV-ROUTING-01부터 EV-ROUTING-05까지의 판정과 trace 최종 결과를 그대로 합산하고, 실행 증거가 없는 항목은 실패로 추정하지 않고 BLOCKED로 유지한다.`
- `limitations`: `고정 fixture 파일·fixture commit·출력 schema·실행별 Skill catalog 증명이 없어 시나리오 본 실행과 routing_decision·actual_execution 관찰을 수행하지 못했다. 현재 작업의 상위 실행 지침은 subagent 생성을 허용하지 않아 MULTI 기대 시나리오의 실제 병렬 효과도 확인할 수 없다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260911-execution-mode-routing-baseline-01` | `2026-09-11T23:40:00+09:00` | `repeated_work` | `extended` | `BLOCKED` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-execution-mode-routing-baseline-02` | `2026-09-11T23:41:00+09:00` | `repeated_work` | `extended` | `BLOCKED` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-execution-mode-routing-baseline-03` | `2026-09-11T23:42:00+09:00` | `repeated_work` | `extended` | `BLOCKED` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-execution-mode-routing-baseline-04` | `2026-09-11T23:43:00+09:00` | `repeated_work` | `extended` | `BLOCKED` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-execution-mode-routing-baseline-05` | `2026-09-11T23:44:00+09:00` | `repeated_work` | `extended` | `BLOCKED` | `1` | `0` | `true` | `true` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `5`
- `included_trace_count`: `5`
- `excluded_trace_count`: `0`
- `pass_count`: `0`
- `fail_count`: `0`
- `blocked_count`: `5`
- `total_attempt_count`: `5`
- `total_rework_count`: `0`
- `unverified_trace_count`: `5`
- `remaining_risk_trace_count`: `5`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-EXECUTION-MODE-ROUTING-01` | `검증 누락` | `5` | `tr-20260911-execution-mode-routing-baseline-01, tr-20260911-execution-mode-routing-baseline-02, tr-20260911-execution-mode-routing-baseline-03, tr-20260911-execution-mode-routing-baseline-04, tr-20260911-execution-mode-routing-baseline-05` | `INSUFFICIENT_EVIDENCE` | `HIGH` | `다섯 시나리오 모두 같은 실행 fixture·고정 commit·결과 schema 부재로 preflight에서 차단됐다. 이는 baseline 라우팅 결함의 반복 증거가 아니라 평가 입력 준비 부족이다.` |

## Candidate 판단

- `candidate_recommendation`: `DEFER`
- `candidate_reason`: `비교 표본 수는 5건이지만 모두 본 실행 전 BLOCKED여서 동일한 미해결 baseline 라우팅 실패나 누락을 관찰하지 못했다. comparison_readiness가 LIMITED이고 OPEN 신호가 없으므로 Candidate A 생성 조건을 충족하지 않는다.`
- `recommended_evaluation`: `Candidate를 만들지 말고 먼저 여섯 fixture 경로, 로컬 검증 명령, 고정 fixture commit, routing-result.schema.json과 Skill catalog/hash 증명 절차를 별도 평가 기반으로 준비한 뒤 같은 SCN-01부터 SCN-05까지 baseline을 재실행한다.`

## 결론

- `conclusion`: `Report 집계 자체는 완전해 READY지만 비교 준비도는 LIMITED다. CREATE와 OPEN은 충족하지 않았고 candidate 판단은 DEFER다. 평가 기반을 준비하기 전에는 Candidate A를 생성하지 않는다.`
