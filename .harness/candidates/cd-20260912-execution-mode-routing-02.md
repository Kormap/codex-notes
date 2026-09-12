# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260912-execution-mode-routing-02`
- `created_at`: `2026-09-12T10:55:00+09:00`
- `baseline_version`: `0.5.0-domain-skill-routing`
- `candidate_status`: `PROMOTED`
- `promoted_at`: `2026-09-12T21:53:11+09:00`
- `promoted_version`: `0.6.0-execution-mode-routing`
- `promotion_trace_id`: `tr-20260912-execution-mode-routing-promotion-01`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260912-execution-mode-routing-a2-baseline-01`
- `source_signal_ids`: `SIG-EXECUTION-MODE-ROUTING-A2-01`
- `problem_statement`: `Candidate A 실제 MULTI SCN-05에서 정상 subtree assignment를 actual changed file exact 목록과 직접 비교한 validator false negative로 EV-ROUTING-03이 실패했다.`
- `evidence_summary`: `Candidate A 구현과 두 module 실제 변경·역할별 테스트·Lead 통합 테스트는 정상이었지만 evaluator가 writer ownership scope와 actual changed files를 한 목록으로 취급했다.`

## 개선안 (`proposed_change`)

- `change_summary`: `Candidate A Skill snapshot은 그대로 두고 공용 evaluator에서 writer scope와 expected changed files를 분리해 정규화된 path segment 기반 포함·중첩을 검증한다.`
- `target_files`: `.harness/evaluations/execution-mode-routing/validate-routing-contract.mjs, .harness/evaluations/execution-mode-routing/test-validate-routing-contract.mjs, .harness/evaluations/execution-mode-routing/test-validate-routing-contract.sh`
- `expected_effect`: `SCN-05의 fixtures/module-a/**와 fixtures/module-b/** 정상 subtree assignment를 수용하면서 범위 이탈, 변경 파일 무소유·다중 소유, exact 중복과 부모·자식 subtree 중첩을 탐지한다.`
- `non_goals`: `Candidate A Skill snapshot 수정, Candidate A REJECTED/DEGRADED 기록 변경, 활성 baseline 반영, version 변경과 승격`
- `rollback_plan`: `Candidate A2 validator·회귀 fixture와 이 재평가 기록만 제거하고 Candidate A 및 활성 baseline을 유지한다.`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `harness-contract`
- `affected_evaluator_ids`: `harness-contract`
- `controlled_inputs`: `fixture commit 82009b4567cec55c2e92439d9294e7c0eee84a34, SCN-01부터 SCN-05 고정 prompt, gpt-5.6-terra medium, approve-for-me workspace-write, ephemeral session, config SHA-256 913b877dc2be3f7bb268bb888c5327a5126f5e928a81249f2ed65d93f2841751, 동일 schema·수정 validator·collaboration 조건`
- `minimum_comparison_pairs`: `5`
- `evaluation_commands`: `.harness/evaluations/execution-mode-routing/test-validate-routing-contract.sh; .harness/evaluations/execution-mode-routing/run-one.sh SCN-NN $ISOLATED_WORKSPACE $RESULT_DIR $SKILL_SNAPSHOT $FROZEN_CONFIG; .harness/evaluations/execution-mode-routing/validate-routing-contract.sh $RESULT_JSON SCN-NN $ISOLATED_WORKSPACE; git diff --check; ./scripts/doctor.sh; ./scripts/test-doctor-harness.sh`
- `regression_scope`: `EV-ROUTING-01부터 EV-ROUTING-05, 정상·범위 이탈·중첩·유사 prefix·exact 중복 fixture, 활성 baseline·사용자 설치 Skill·Candidate A snapshot 불변`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `cmp-execution-mode-routing-a2-01` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-a2-baseline-01` | `tr-20260912-execution-mode-routing-a2-candidate-01` | `IMPROVED` | `baseline FAIL에서 A2 PASS; 독립 조사 gate·fallback·무변경·통합 검증 일치` |
| `cmp-execution-mode-routing-a2-02` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-a2-baseline-02` | `tr-20260912-execution-mode-routing-a2-candidate-02` | `IMPROVED` | `baseline FAIL에서 A2 PASS; 순차 API 수정의 MAIN·exact 변경·통합 검증 일치` |
| `cmp-execution-mode-routing-a2-03` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-a2-baseline-03` | `tr-20260912-execution-mode-routing-a2-candidate-03` | `IMPROVED` | `baseline FAIL에서 A2 PASS; 독립 리뷰 gate·fallback·무변경·통합 검증 일치` |
| `cmp-execution-mode-routing-a2-04` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-a2-baseline-04` | `tr-20260912-execution-mode-routing-a2-candidate-04` | `IMPROVED` | `baseline FAIL에서 A2 PASS; 공유 계약의 MAIN·exact 변경·통합 검증 일치` |
| `cmp-execution-mode-routing-a2-05` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-a2-baseline-05` | `tr-20260912-execution-mode-routing-a2-candidate-05` | `IMPROVED` | `baseline FAIL에서 A2 PASS; 두 module exact 변경과 적법한 fallback·통합 검증 일치` |

## 판정

- `evaluation_result`: `IMPROVED`
- `promotion_recommendation`: `PROMOTE`
- `decision_reason`: `수정된 동일 validator와 통제 입력에서 다섯 비교 쌍이 모두 baseline FAIL에서 A2 PASS로 개선됐고, 별도 실제 MULTI SCN-01·03·05도 PASS했다. SCN-05는 정상 subtree assignment, actual changed files exact 목록, 변경 파일당 단일 writer, scope 비중첩, 역할별 테스트와 Lead 통합 검증을 모두 충족했다.`
- `remaining_risks`: `실제 MULTI 보강의 시간 효과는 측정하지 않았고 SCN-03 semantic finding은 synthetic diff 범위다.`
- `approved_by`: `repository owner`

## 실제 delegation 보강 평가

| 시나리오 | Trace | 실제 실행 | 실제 위임 | 결과 | 핵심 근거 |
|---|---|---|---:|---|---|
| `SCN-01` | `tr-20260912-execution-mode-routing-a2-delegated-01` | `MULTI` | `2` | `PASS` | `두 Researcher의 독립 근거를 Lead가 채택·통합했고 workspace는 무변경` |
| `SCN-03` | `tr-20260912-execution-mode-routing-a2-delegated-03` | `MULTI` | `3` | `PASS` | `보안·성능·회귀 Reviewer 결과를 Lead가 중복 제거해 통합` |
| `SCN-05` | `tr-20260912-execution-mode-routing-a2-delegated-05` | `MULTI` | `2` | `PASS` | `두 subtree writer와 exact actual 변경, focused test 2건·Lead 통합 테스트 통과` |
