# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260912-execution-mode-routing-01`
- `created_at`: `2026-09-12T09:00:00+09:00`
- `baseline_version`: `0.5.0-domain-skill-routing`
- `candidate_status`: `REJECTED`
- `promoted_at`: `NOT_APPLICABLE`
- `promoted_version`: `NOT_APPLICABLE`
- `promotion_trace_id`: `NOT_APPLICABLE`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260912-execution-mode-routing-baseline-01`
- `source_signal_ids`: `SIG-EXECUTION-MODE-ROUTING-01`
- `problem_statement`: `활성 dev-harness에는 네 gate와 routing decision, actual execution 또는 fallback, 역할 소유권과 Lead 통합 검증을 일관되게 연결하는 실행 모드 체크포인트가 없다.`
- `evidence_summary`: `같은 fixture commit과 실행 환경의 다섯 baseline trace가 모두 gate, decision, fallback 또는 assignment 계약 중 하나 이상에서 FAIL했다.`

## 개선안 (`proposed_change`)

- `change_summary`: `격리된 dev-harness Skill snapshot에 네 gate 기반 실행 모드 라우팅과 실제 실행·fallback·소유권·통합 검증 체크포인트를 추가한다.`
- `target_files`: `.harness/candidates/implementations/cd-20260912-execution-mode-routing-01/skills/dev-harness/SKILL.md`
- `expected_effect`: `동일한 다섯 통제 입력에서 gate와 routing decision이 기대값에 맞고, 상위 지침이 delegation을 금지하면 적법한 MAIN_FALLBACK을 기록하며, MAIN과 실제 MULTI 실행의 역할·소유권·통합 계약을 지킨다.`
- `non_goals`: `활성 skills/dev-harness/SKILL.md, baseline version, custom agent 패키징·설치, 역할 계약, trace schema와 evaluator 변경`
- `rollback_plan`: `격리 candidate 디렉터리와 candidate 문서를 제거하고 활성 0.5.0-domain-skill-routing을 그대로 유지한다.`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `harness-contract`
- `affected_evaluator_ids`: `harness-contract`
- `controlled_inputs`: `fixture commit 82009b4567cec55c2e92439d9294e7c0eee84a34, SCN-01부터 SCN-05까지의 고정 prompt, gpt-5.6-terra medium, approve-for-me workspace-write, ephemeral session, config SHA-256 913b877dc2be3f7bb268bb888c5327a5126f5e928a81249f2ed65d93f2841751, 동일 schema·validator`
- `minimum_comparison_pairs`: `5`
- `evaluation_commands`: `.harness/evaluations/execution-mode-routing/run-one.sh SCN-NN $ISOLATED_WORKSPACE $RESULT_DIR $CANDIDATE_SKILL $FROZEN_CONFIG; .harness/evaluations/execution-mode-routing/validate-routing-contract.sh $RESULT_JSON SCN-NN $ISOLATED_WORKSPACE; git diff --check; ./scripts/doctor.sh; ./scripts/test-doctor-harness.sh`
- `regression_scope`: `활성 baseline과 사용자 설치 상태 불변, 기존 Harness 문서·Diagnostics 계약, current-request evaluator의 EV-ROUTING-01부터 EV-ROUTING-05까지`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `cmp-execution-mode-routing-01` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-baseline-01` | `tr-20260912-execution-mode-routing-candidate-01` | `IMPROVED` | `독립 조사에서 정확한 MULTI 결정과 적법한 MAIN_FALLBACK, 무변경·통합 검증을 확인했다.` |
| `cmp-execution-mode-routing-02` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-baseline-02` | `tr-20260912-execution-mode-routing-candidate-02` | `IMPROVED` | `순차 API 수정에서 정확한 MAIN 결정과 단일 writer·통합 검증을 확인했다.` |
| `cmp-execution-mode-routing-03` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-baseline-03` | `tr-20260912-execution-mode-routing-candidate-03` | `IMPROVED` | `독립 관점 리뷰에서 정확한 MULTI 결정과 적법한 MAIN_FALLBACK을 확인했다.` |
| `cmp-execution-mode-routing-04` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-baseline-04` | `tr-20260912-execution-mode-routing-candidate-04` | `IMPROVED` | `공유 config·migration에서 정확한 MAIN 결정과 단일 writer·exact 통합 명령을 확인했다.` |
| `cmp-execution-mode-routing-05` | `harness-contract` | `harness-contract` | `tr-20260912-execution-mode-routing-baseline-05` | `tr-20260912-execution-mode-routing-candidate-05` | `IMPROVED` | `독립 module 수정에서 정확한 MULTI 결정, 적법한 MAIN_FALLBACK과 비중첩 변경을 확인했다.` |

## 판정

- `evaluation_result`: `DEGRADED`
- `promotion_recommendation`: `REJECT`
- `decision_reason`: `최종 candidate Skill hash 4cc2edd…의 기존 다섯 비교 쌍은 baseline FAIL에서 candidate PASS로 개선됐다. 추가로 delegation을 명시 허용한 보강 평가에서 SCN-01과 SCN-03은 실제 MULTI로 PASS했지만 SCN-05는 두 Implementer의 writer 범위를 정확한 파일이 아닌 디렉터리로 배정해 EV-ROUTING-03이 FAIL했다. 활성 baseline과 Candidate 구현은 변경하지 않았다.`
- `remaining_risks`: `실제 병렬 writer 실행에서 파일 단위 소유권을 강제하지 못한다. Candidate A의 assignment 계약을 보완하고 SCN-01·03·05를 동일 조건으로 재평가하기 전에는 승격하지 않는다.`
- `approved_by`: `PENDING`

## 실제 delegation 보강 평가

| 시나리오 | Trace | 실제 실행 | 실제 위임 | 결과 | 핵심 근거 |
|---|---|---|---:|---|---|
| `SCN-01` | `tr-20260912-execution-mode-routing-delegated-01` | `MULTI` | `2` | `PASS` | `두 Researcher의 읽기 전용 범위, 결과 채택과 통합 검증이 일치했다.` |
| `SCN-03` | `tr-20260912-execution-mode-routing-delegated-03` | `MULTI` | `3` | `PASS` | `보안·성능·회귀 Reviewer를 분리하고 중복 finding을 Lead가 통합했다.` |
| `SCN-05` | `tr-20260912-execution-mode-routing-delegated-05` | `MULTI` | `2` | `FAIL` | `실제 변경과 통합 테스트는 통과했지만 writer assignment가 exact 파일 대신 디렉터리였다.` |
