# 최소 Harness Trace

## 메타데이터

- `schema_version`: `1`
- `trace_id`: `tr-YYYYMMDD-<slug>-<sequence>`
- `recorded_at`: `YYYY-MM-DDThh:mm:ss+09:00`
- `baseline_version`: `<.harness/baseline/version.md의 버전>`
- `trace_level`: `minimum`
- `final_result`: `PASS | FAIL | BLOCKED`

## 작업

- `task_type`: `bug_fix | feature | behavior_change | repeated_work | code_review | other`
- `task_reference`: `<적용한 task 문서 경로 또는 현재 요청 식별자>`
- `request_summary`: `<민감정보를 제외한 요청 요약>`
- `in_scope`: `<수행 범위>`
- `out_of_scope`: `<금지하거나 제외한 범위 | NONE>`

## 성공 조건 (`success_criteria`)

- [ ] `SC-01`: `<검증 가능한 성공 조건 1>`
- [ ] `SC-02`: `<검증 가능한 성공 조건 2>`

## 적용 Skill

- `applied_skills`: `<Skill 이름과 적용 목적 | NONE>`

## 변경

- `changed_files`: `<저장소 상대 경로 목록 | NONE>`
- `change_summary`: `<요청과 연결되는 변경 요약>`
- `approval_summary`: `<승인 요청·결정·수행 여부 | NONE>`
- `external_actions`: `<수행한 외부 행동 | NONE>`

## 시도와 재작업

- `attempt_count`: `1`
- `rework_count`: `0`
- `rework_summary`: `<재작업 원인과 변경 | NONE>`

## 검증 결과 (`evaluator_results`)

| 평가자 (`evaluator_id`) | 명령 또는 방법 (`command_or_method`) | 결과 (`result`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|
| `<식별자>` | `<재실행 가능한 명령 또는 검토 방법>` | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `<종료 코드와 핵심 결과>` |

## 미검증 항목과 남은 위험

- `unverified`: `<검증하지 못한 항목과 사유 | NONE>`
- `remaining_risks`: `<남은 위험과 영향 | NONE>`

## 최종 판정

- `result_reason`: `<성공 조건과 evaluator에 근거한 최종 판정 이유>`
- `user_report_consistency`: `CONSISTENT | INCONSISTENT | PENDING`
