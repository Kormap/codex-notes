# Harness 집계 Report

## 메타데이터

- `schema_version`: `1`
- `report_id`: `rp-20260906-context-refactor-01`
- `generated_at`: `2026-09-06T23:40:37+09:00`
- `baseline_version`: `0.3.0-reference-lifecycle`
- `report_status`: `READY`
- `comparison_readiness`: `READY`

## 집계 범위

- `window_start`: `2026-09-06T23:35:51+09:00`
- `window_end`: `2026-09-06T23:40:37+09:00`
- `selection_rule`: `기준 revision f394275ab95958b3ee474035e73f937286f58f80과 현재 후보를 global-only, global-repo, repo-only의 동일 context-refactor evaluator로 평가한 여섯 trace를 포함한다.`
- `aggregation_method`: `세 discovery 조건별 baseline과 candidate 한 쌍을 구성하고 trace의 최종 판정, 시도, 재작업과 검증 한계를 합산한다.`
- `limitations`: `문자 수 측정이며 tokenizer 실측이 아니다. 실제 Windows와 새 LLM 세션 실행은 포함하지 않았고 같은 세션에서 작성자와 검토자를 겸임했다.`

## Source Trace (`source_traces`)

| Trace (`trace_id`) | 기록 시각 (`recorded_at`) | 작업 유형 (`task_type`) | 수준 (`trace_level`) | 결과 (`final_result`) | 시도 (`attempt_count`) | 재작업 (`rework_count`) | 미검증 (`has_unverified`) | 남은 위험 (`has_remaining_risk`) | 포함 (`inclusion`) |
|---|---|---|---|---|---|---|---|---|---|
| `tr-20260906-context-baseline-01` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260906-context-baseline-02` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `FAIL` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260906-context-baseline-03` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260906-context-candidate-01` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260906-context-candidate-02` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |
| `tr-20260906-context-candidate-03` | `2026-09-06T23:35:51+09:00` | `code_review` | `extended` | `PASS` | `1` | `0` | `true` | `true` | `INCLUDED` |

## 집계 (`aggregate_counts`)

- `source_trace_count`: `6`
- `included_trace_count`: `6`
- `excluded_trace_count`: `0`
- `pass_count`: `5`
- `fail_count`: `1`
- `blocked_count`: `0`
- `total_attempt_count`: `6`
- `total_rework_count`: `0`
- `unverified_trace_count`: `6`
- `remaining_risk_trace_count`: `6`

## 관찰 신호 (`signals`)

| 신호 (`signal_id`) | 범주 (`category`) | 발생 수 (`occurrence_count`) | 근거 trace (`evidence_trace_ids`) | 상태 (`status`) | 심각도 (`severity`) | 해석 (`interpretation`) |
|---|---|---|---|---|---|---|
| `SIG-CONTEXT-REFRACTOR-01` | `재작업` | `3` | `tr-20260906-context-baseline-01, tr-20260906-context-baseline-02, tr-20260906-context-baseline-03` | `OPEN` | `HIGH` | `세 discovery 조건의 기준은 공통 원본 확보 후 각각 14050, 28100, 14050자다. 후보는 6145, 7448, 7448자로 줄고 모든 필수 검사를 통과했으므로 승격 전 비교 대상으로 유지한다.` |

## Candidate 판단

- `candidate_recommendation`: `CREATE`
- `candidate_reason`: `세 통제 조건에서 지속적으로 관찰된 context 비용이 후보에서 모두 감소했고, 원본 중복 제거와 필수 규칙·검증 계약 보존을 같은 evaluator로 재현할 수 있다.`
- `recommended_evaluation`: `context-refactor task/evaluator로 세 baseline·candidate 쌍의 문자 수, 원본 횟수, 규칙 발견 경로와 전체 회귀를 대조한다.`

## 결론

- `conclusion`: `현재 후보는 세 비교 쌍에서 개선됐고 회귀 검사를 통과했다. 실제 Windows·새 LLM 실행과 reviewer 독립성 한계를 남긴 채 ACCEPTED candidate로 승격 승인 대기 상태를 준비할 수 있다.`
