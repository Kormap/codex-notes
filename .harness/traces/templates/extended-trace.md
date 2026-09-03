# 확장 Harness Trace

이 템플릿은 [최소 trace 템플릿](minimum-trace.md)의 필수 항목을 모두 포함한다. 적용되지 않는 확장 섹션은 삭제하지 않고 `NOT_APPLICABLE`로 표시한다.

## 메타데이터

- `schema_version`: `1`
- `trace_id`: `tr-YYYYMMDD-<slug>-<sequence>`
- `recorded_at`: `YYYY-MM-DDThh:mm:ss+09:00`
- `baseline_version`: `<.harness/baseline/version.md의 버전>`
- `trace_level`: `extended`
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

## 확장 메타데이터

- `trigger_high_risk`: `true | false`
- `trigger_repeated_evaluation`: `true | false`
- `trigger_multi_agent`: `true | false`

## 고위험 근거 (`high_risk_evidence`)

### 위험 (`risks`)

| 위험 (`risk`) | 영향 (`impact`) | 통제 (`control`) | 잔여 위험 (`residual_risk`) |
|---|---|---|---|
| `<위험 항목>` | `<영향>` | `<적용한 통제>` | `<남은 위험>` |

### 승인 (`approvals`)

| 요청 시각 (`requested_at`) | 행동과 정확한 대상 (`action_target`) | 결정 (`decision`) | 수행 (`performed`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|
| `<ISO 8601>` | `<민감정보 없는 승인 대상>` | `APPROVED`, `DENIED`, `PENDING` 중 하나 | `true`, `false` 중 하나 | `<결정과 실제 수행 결과>` |

### 외부 행동과 복구 (`external_actions_recovery`)

- `external_action_details`: `<외부 상태 변경과 결과 | NONE | NOT_APPLICABLE>`
- `failure_observed`: `<실패와 영향 | NONE | NOT_APPLICABLE>`
- `recovery_decision`: `<복구 또는 미수행 판단과 근거 | NONE | NOT_APPLICABLE>`
- `recovery_result`: `<복구 결과 | NONE | NOT_APPLICABLE>`

## 반복 평가 근거 (`repeated_evaluation_evidence`)

- `run_id`: `<run-<sequence> | NOT_APPLICABLE>`
- `comparison_target`: `<비교 trace_id, baseline 또는 candidate 식별자 | NOT_APPLICABLE>`
- `controlled_inputs`: `<실행 간 동일하게 유지한 입력과 환경 | NOT_APPLICABLE>`

### 비교 결과 (`comparison_results`)

| 평가자 (`evaluator_id`) | 이전 결과 (`previous_result`) | 현재 결과 (`current_result`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|
| `<동일 evaluator 식별자>` | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `PASS`, `FAIL`, `BLOCKED` 중 하나 | `IMPROVED`, `UNCHANGED`, `DEGRADED` 중 하나 | `<차이와 원인>` |

- `rework_cause`: `<재작업을 유발한 반복 실패·누락 | NONE | NOT_APPLICABLE>`
- `comparison_limitations`: `<비교할 수 없는 조건 | NONE | NOT_APPLICABLE>`

## 멀티에이전트 근거 (`multi_agent_evidence`)

### 역할 배정과 소유권 (`agent_assignments`)

| 에이전트·작업 ID (`agent_task_id`) | 역할 (`role`) | 배정 범위 (`assigned_scope`) | 쓰기 가능 파일 (`writable_files`) | 상태 (`status`) |
|---|---|---|---|---|
| `<비민감 식별자>` | `Lead`, `Researcher`, `Implementer`, `Reviewer`, `Verifier` 중 하나 | `<담당 범위>` | `<저장소 상대 경로 또는 NONE>` | `COMPLETED`, `NEEDS_LEAD_DECISION`, `NEEDS_USER_APPROVAL`, `BLOCKED` 중 하나 |

### 위임과 역할 결과 (`delegations`)

| 위임자 (`from`) | 수임자 (`to`) | 계약 요약 (`contract_summary`) | 결과 채택 (`result_adopted`) | 결과·근거 요약 (`result_evidence_summary`) |
|---|---|---|---|---|
| `Lead` | `<비민감 식별자>` | `<목표·범위·금지 행동·evaluator>` | `ADOPTED`, `REJECTED`, `PARTIAL` 중 하나 | `<반환 결과와 채택 판단>` |

- `role_separation`: `<역할 겸임과 독립성 충족 여부 | NOT_APPLICABLE>`
- `ownership_conflicts`: `<충돌과 해결 | NONE | NOT_APPLICABLE>`
- `escalations`: `<상태 변경, 결정과 재개 조건 | NONE | NOT_APPLICABLE>`

### 통합과 최종 검증 (`integration_verification`)

- `integrated_by`: `<Lead 식별자 | NOT_APPLICABLE>`
- `adopted_changes`: `<채택한 역할별 변경 | NOT_APPLICABLE>`
- `rejected_or_reworked_results`: `<보류·폐기·재작업 결과와 이유 | NONE | NOT_APPLICABLE>`
- `integration_evaluator`: `<통합 상태에서 실행한 evaluator와 결과 | NOT_APPLICABLE>`
- `independence_limitations`: `<독립 리뷰·검증 한계와 남은 위험 | NONE | NOT_APPLICABLE>`
