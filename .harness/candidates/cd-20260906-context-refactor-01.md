# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260906-context-refactor-01`
- `created_at`: `2026-09-06T23:40:37+09:00`
- `baseline_version`: `0.3.0-reference-lifecycle`
- `candidate_status`: `PROMOTED`
- `promoted_at`: `2026-09-06T23:59:09+09:00`
- `promoted_version`: `0.4.0-context-routing`
- `promotion_trace_id`: `tr-20260906-context-refactor-promotion-01`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260906-context-refactor-01`
- `source_signal_ids`: `SIG-CONTEXT-REFRACTOR-01`
- `problem_statement`: `전역 공통 지침이 크고 이 저장소에서는 같은 원본이 전역과 프로젝트 범위에서 중복 주입되며, 조건부 계약을 항상 읽어 persistent context를 소모한다.`
- `evidence_summary`: `세 discovery 조건의 기준 원본 확보 비용은 14050, 28100, 14050자였고 후보는 6145, 7448, 7448자다. 후보는 각 조건에서 원본을 한 번 확보하고 필수 규칙의 발견 경로와 전체 회귀를 유지했다.`

## 개선안 (`proposed_change`)

- `change_summary`: `공통 규칙을 압축하고 상세 운영·Harness 계약을 조건부 skill과 runtime 문서로 이동하며 프로젝트 override로 중복 주입을 제거한다. 최초 Windows 복사 설치가 첫 실행에 중앙 Harness 경로를 기록하도록 보완한다.`
- `target_files`: `AGENTS.md, AGENTS.override.md, docs/AGENTS.ko.md, README.md, .harness/, skills/dev-harness/, skills/engineering-standards/, scripts/setup.sh, scripts/doctor.sh, scripts/test-doctor-harness.sh, .harness/candidates/implementations/cd-20260906-context-refactor-01/validate-context-refactor.sh`
- `expected_effect`: `필수 행동과 검증 계약을 보존하면서 세 discovery 조건의 공통 원본 확보 문자 수를 줄이고 전역·저장소 중복을 제거한다.`
- `non_goals`: `실제 agent 품질 향상 단정, 실제 Windows 검증 완료 주장, 기존 report·candidate 근거 변경, 승인 없는 활성 version 변경`
- `rollback_plan`: `이 version의 변경 commit을 되돌리고 이전 활성 version을 복원하는 별도 승인 변경을 사용한다.`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `context-refactor`
- `affected_evaluator_ids`: `context-refactor`
- `controlled_inputs`: `기준 revision f394275ab95958b3ee474035e73f937286f58f80과 현재 후보 snapshot, 세 discovery 조건, 동일 측정 script·evaluator와 macOS fixture 환경`
- `minimum_comparison_pairs`: `3`
- `evaluation_commands`: `.harness/candidates/implementations/cd-20260906-context-refactor-01/validate-context-refactor.sh BASELINE_ROOT CANDIDATE_ROOT; git diff HEAD --check; ./scripts/doctor.sh; ./scripts/test-doctor-harness.sh; sh scripts/test-doc-sync.sh`
- `regression_scope`: `지침 우선순위·안전·검증·도메인 기준, 복합 evaluator, 고위험 우선, trace·report·candidate 계약, symlink와 Windows 복사 설치의 정상·오류 경로`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `cmp-context-refactor-01` | `context-refactor` | `context-refactor` | `tr-20260906-context-baseline-01` | `tr-20260906-context-candidate-01` | `IMPROVED` | `global-only에서 원본 확보 비용이 14050자에서 6145자로 감소하고 두 snapshot의 해당 회귀가 통과했다.` |
| `cmp-context-refactor-02` | `context-refactor` | `context-refactor` | `tr-20260906-context-baseline-02` | `tr-20260906-context-candidate-02` | `IMPROVED` | `global-repo에서 원본 두 번 28100자가 원본 한 번과 override 7448자로 줄고 후보 전체 회귀가 통과했다.` |
| `cmp-context-refactor-03` | `context-refactor` | `context-refactor` | `tr-20260906-context-baseline-03` | `tr-20260906-context-candidate-03` | `IMPROVED` | `repo-only에서 원본 확보 비용이 14050자에서 override와 추가 원본 읽기 7448자로 감소하고 두 snapshot의 해당 회귀가 통과했다.` |

## 판정

- `evaluation_result`: `IMPROVED`
- `promotion_recommendation`: `PROMOTE`
- `decision_reason`: `세 비교 쌍 모두 context 비용이 감소했고 후보에서 원본은 한 번만 확보되며 필수 규칙 의미와 설치·Diagnostics 회귀가 유지돼 저장소 소유자의 승인으로 0.4.0-context-routing에 승격했다.`
- `remaining_risks`: `실제 Windows, 새 LLM 세션과 tokenizer는 미검증이며 정적 문서 검토는 행동 동등성을 증명하지 않는다. 동일 세션에서 후보 작성과 검토를 겸임했다.`
- `approved_by`: `repository owner`
