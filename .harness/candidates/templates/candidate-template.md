# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-YYYYMMDD-<slug>-<sequence>`
- `created_at`: `YYYY-MM-DDThh:mm:ss+09:00`
- `baseline_version`: `<평가 대상 baseline 버전>`
- `candidate_status`: `<DRAFT, READY, EVALUATING, ACCEPTED, PROMOTED, REJECTED, DEFERRED 중 하나>`
- `promoted_at`: `<YYYY-MM-DDThh:mm:ss+09:00 또는 NOT_APPLICABLE>`
- `promoted_version`: `<승격된 baseline 버전 또는 NOT_APPLICABLE>`
- `promotion_trace_id`: `<tr-YYYYMMDD-<slug>-<sequence> 또는 NOT_APPLICABLE>`

## 근거 (`source_evidence`)

- `source_report_id`: `<rp-YYYYMMDD-<slug>-<sequence>>`
- `source_signal_ids`: `<쉼표로 구분한 OPEN signal ID>`
- `problem_statement`: `<반복된 문제와 영향>`
- `evidence_summary`: `<source report에서 확인한 비민감 근거>`

## 개선안 (`proposed_change`)

- `change_summary`: `<한 가지 검증 가능한 개선안>`
- `target_files`: `<저장소 상대 경로, 쉼표 구분>`
- `expected_effect`: `<개선되어야 할 관찰 가능한 결과>`
- `non_goals`: `<변경하지 않을 범위 또는 NONE>`
- `rollback_plan`: `<candidate 변경을 제거하는 방법>`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `<쉼표로 구분한 task_id>`
- `affected_evaluator_ids`: `<쉼표로 구분한 evaluator_id>`
- `controlled_inputs`: `<baseline과 candidate 실행에 동일하게 적용할 입력·환경>`
- `minimum_comparison_pairs`: `<1 이상의 정수>`
- `evaluation_commands`: `<재실행 가능한 명령 또는 검토 방법>`
- `regression_scope`: `<함께 유지되어야 할 기존 성공 조건>`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` |

## 판정

- `evaluation_result`: `<PENDING, IMPROVED, UNCHANGED, DEGRADED, BLOCKED 중 하나>`
- `promotion_recommendation`: `<PENDING, PROMOTE, REVISE, REJECT 중 하나>`
- `decision_reason`: `<비교 결과, 회귀와 한계에 근거한 판단>`
- `remaining_risks`: `<남은 위험 또는 NONE>`
- `approved_by`: `<repository owner 또는 PENDING>`
