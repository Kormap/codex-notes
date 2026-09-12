# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260912-execution-mode-routing-baseline-01`
- `generated_at`: `2026-09-12T00:22:00+09:00`
- `baseline_version`: `0.5.0-domain-skill-routing`
- `report_status`: `READY`
- `comparison_readiness`: `READY`

## 집계 범위

- `window_start`: `2026-09-12T00:12:00+09:00`
- `window_end`: `2026-09-12T00:16:00+09:00`
- `selection_rule`: `execution-mode-routing-current-request-v1의 SCN-01부터 SCN-05까지 고정 fixture commit과 동일 Skill·config·모델·sandbox 조건으로 최종 재실행한 baseline trace를 포함한다.`
- `aggregation_method`: `각 trace의 EV-ROUTING-01부터 EV-ROUTING-05까지의 판정과 최종 결과를 그대로 집계하고, 동일한 실행 모드 계약 부재에서 발생한 gate·decision·fallback·assignment 불일치를 하나의 신호로 묶었다.`
- `limitations`: `상위 실행 지침이 명시적 subagent 요청 없는 delegation을 금지해 MULTI 기대 시나리오의 병렬 품질·시간 효과는 측정하지 못했다. 이 제약은 evaluator가 허용한 MAIN_FALLBACK 사유지만 baseline은 일부 실행에서 gate와 decision에 섞거나 필수 fallback 근거를 누락했다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260912-execution-mode-routing-baseline-01` | `2026-09-12T00:12:00+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-baseline-02` | `2026-09-12T00:13:00+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-baseline-03` | `2026-09-12T00:14:00+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-baseline-04` | `2026-09-12T00:15:00+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `false` | `true` | `INCLUDED` |
| `tr-20260912-execution-mode-routing-baseline-05` | `2026-09-12T00:16:00+09:00` | `repeated_work` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `5`
- `included_trace_count`: `5`
- `excluded_trace_count`: `0`
- `pass_count`: `0`
- `fail_count`: `5`
- `blocked_count`: `0`
- `total_attempt_count`: `5`
- `total_rework_count`: `0`
- `unverified_trace_count`: `3`
- `remaining_risk_trace_count`: `5`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-EXECUTION-MODE-ROUTING-01` | `검증 누락` | `5` | `tr-20260912-execution-mode-routing-baseline-01, tr-20260912-execution-mode-routing-baseline-02, tr-20260912-execution-mode-routing-baseline-03, tr-20260912-execution-mode-routing-baseline-04, tr-20260912-execution-mode-routing-baseline-05` | `OPEN` | `HIGH` | `다섯 통제 입력 모두 하나 이상의 gate가 틀리거나 gate가 맞아도 routing decision·fallback·assignment 계약이 어긋났다. 활성 dev-harness에는 네 gate와 실행·fallback 증거를 일관되게 연결하는 실행 모드 라우팅 체크포인트가 없다.` |

## Candidate 판단

- `candidate_recommendation`: `CREATE`
- `candidate_reason`: `동일 fixture commit과 실행 환경의 다섯 비교 가능한 trace에서 같은 실행 모드 계약 부재가 반복됐고, 영향을 받는 current-request evaluator와 동일 입력 재평가 방법이 고정됐다. report는 READY, comparison_readiness는 READY이며 OPEN 신호가 있으므로 Candidate A 생성 조건을 충족한다.`
- `recommended_evaluation`: `격리 Candidate A에서 dev-harness Skill snapshot만 변경하고 fixture commit 82009b4, gpt-5.6-terra medium, frozen config SHA-256 913b877…, 동일 sandbox·schema·validator로 SCN-01부터 SCN-05까지 재실행해 각 baseline trace와 한 쌍으로 비교한다.`

## 결론

- `conclusion`: `CREATE/READY/OPEN을 모두 충족한다. 이번 요청은 Candidate A 생성 전까지이므로 candidate 파일이나 구현은 만들지 않고, 다음 별도 요청에서 source signal SIG-EXECUTION-MODE-ROUTING-01만 대상으로 Candidate A를 구현·비교 평가한다.`
