# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260911-domain-skill-routing-01`
- `generated_at`: `2026-09-11T22:45:00+09:00`
- `baseline_version`: `0.4.0-context-routing`
- `report_status`: `READY`
- `comparison_readiness`: `READY`

## 집계 범위

- `window_start`: `2026-09-11T22:40:00+09:00`
- `window_end`: `2026-09-11T22:42:00+09:00`
- `selection_rule`: `활성 dev-harness에서 JPA API, Vue UI, DB backfill·배포의 세 대표 입력을 동일 context-refactor evaluator와 네 단계 라우팅 기준으로 검토한 baseline trace를 포함한다.`
- `aggregation_method`: `각 입력에서 작업 유형, 주 도메인, 교차 관심사, 테스트의 발견 경로와 최종 evaluator 소유권을 동일 기준으로 판정하고 trace 결과를 합산한다.`
- `limitations`: `정적 문서 계약 검토이며 새 Codex 세션의 실제 Skill 자동 선택과 독립 reviewer 검증은 포함하지 않았다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260911-domain-routing-baseline-01` | `2026-09-11T22:40:00+09:00` | `code_review` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-domain-routing-baseline-02` | `2026-09-11T22:41:00+09:00` | `code_review` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260911-domain-routing-baseline-03` | `2026-09-11T22:42:00+09:00` | `code_review` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `3`
- `included_trace_count`: `3`
- `excluded_trace_count`: `0`
- `pass_count`: `0`
- `fail_count`: `3`
- `blocked_count`: `0`
- `total_attempt_count`: `3`
- `total_rework_count`: `0`
- `unverified_trace_count`: `3`
- `remaining_risk_trace_count`: `3`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-DOMAIN-SKILL-ROUTING-01` | `검증 누락` | `3` | `tr-20260911-domain-routing-baseline-01, tr-20260911-domain-routing-baseline-02, tr-20260911-domain-routing-baseline-03` | `OPEN` | `HIGH` | `세 대표 입력 모두 task/evaluator 선택 이후 도메인 Skill을 네 단계로 조합하는 발견 경로가 활성 dev-harness에 없어 일관된 적용을 보장할 수 없다.` |

## Candidate 판단

- `candidate_recommendation`: `CREATE`
- `candidate_reason`: `동일한 라우팅 누락이 세 대표 입력에서 반복됐고, 격리된 dev-harness 후보에 네 단계 선택 조건을 추가한 뒤 같은 입력으로 재평가할 수 있다.`
- `recommended_evaluation`: `context-refactor task/evaluator로 각 baseline trace와 candidate trace를 한 쌍으로 비교하고 candidate 구조 검사, doctor, Harness 회귀와 의미 검토를 수행한다.`

## 결론

- `conclusion`: `활성 dev-harness는 task/evaluator는 선택하지만 기존 전문 Skill의 조합 순서를 보장하지 않는다. 네 단계 조건부 라우팅을 격리 candidate로 작성해 비교 평가한다.`
