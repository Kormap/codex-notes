# Harness Candidate

## 메타데이터

- `schema_version`: `1`
- `candidate_id`: `cd-20260911-domain-skill-routing-01`
- `created_at`: `2026-09-11T22:46:00+09:00`
- `baseline_version`: `0.4.0-context-routing`
- `candidate_status`: `PROMOTED`
- `promoted_at`: `2026-09-11T23:05:00+09:00`
- `promoted_version`: `0.5.0-domain-skill-routing`
- `promotion_trace_id`: `tr-20260911-domain-routing-promotion-01`

## 근거 (`source_evidence`)

- `source_report_id`: `rp-20260911-domain-skill-routing-01`
- `source_signal_ids`: `SIG-DOMAIN-SKILL-ROUTING-01`
- `problem_statement`: `dev-harness가 task와 evaluator는 선택하지만 기존 전문 Skill을 작업 유형, 주 도메인, 교차 관심사, 테스트 순서로 조합하는 계약이 없어 대표 개발 요청에서 적용이 상위 description 매칭에 의존한다.`
- `evidence_summary`: `JPA API, Vue UI, DB backfill·배포의 세 baseline trace가 모두 동일한 라우팅 발견 경로 부재로 FAIL했다.`

## 개선안 (`proposed_change`)

- `change_summary`: `task/evaluator 선택 다음에 작업 유형, 주 도메인, 교차 관심사, 테스트의 네 단계로 저장소 전문 Skill 11개를 최소 조건부 적용하는 라우팅 계약을 추가한다.`
- `target_files`: `skills/dev-harness/SKILL.md`
- `expected_effect`: `대표 요청에서 필요한 전문 Skill과 조합 순서가 발견되고, 불필요한 Skill 로딩과 evaluator 소유권 변경 없이 도메인 기준을 적용한다.`
- `non_goals`: `전문 Skill 본문 복제, 모든 세션·artifact Skill의 고정 등록, keyword만으로 자동 적용, task/evaluator 또는 실행 권한 변경`
- `rollback_plan`: `candidate 구현을 제거하고 활성 0.4.0-context-routing의 dev-harness를 유지한다.`

## 평가 계획 (`evaluation_plan`)

- `affected_task_ids`: `context-refactor`
- `affected_evaluator_ids`: `context-refactor`
- `controlled_inputs`: `동일 baseline, candidate SKILL.md, JPA API·Vue UI·DB backfill 배포의 세 입력, 네 단계 선택 기준과 최종 evaluator 소유권`
- `minimum_comparison_pairs`: `3`
- `evaluation_commands`: `.harness/candidates/implementations/cd-20260911-domain-skill-routing-01/validate-domain-skill-routing.sh; git diff --check; ./scripts/doctor.sh; ./scripts/test-doctor-harness.sh`
- `regression_scope`: `task/evaluator 우선 선택, 최소 Skill 로딩, 구체 Skill 정본, 상위 지침·승인 범위, 설치 및 기존 Harness 계약`

## 평가 결과 (`comparison_results`)

| 비교 쌍 (`comparison_id`) | Task (`task_id`) | Evaluator (`evaluator_id`) | Baseline trace (`baseline_trace_id`) | Candidate trace (`candidate_trace_id`) | 품질 변화 (`quality_change`) | 근거 요약 (`evidence_summary`) |
|---|---|---|---|---|---|---|
| `cmp-domain-routing-01` | `context-refactor` | `context-refactor` | `tr-20260911-domain-routing-baseline-01` | `tr-20260911-domain-routing-candidate-01` | `IMPROVED` | `JPA API 입력에서 engineering-standards, jpa-performance-review, transaction audit와 test-generator의 단계별 발견 경로가 추가되고 evaluator 소유권이 유지됐다.` |
| `cmp-domain-routing-02` | `context-refactor` | `context-refactor` | `tr-20260911-domain-routing-baseline-02` | `tr-20260911-domain-routing-candidate-02` | `IMPROVED` | `Vue UI 입력에서 frontend-ui-review와 테스트 변경 조건이 발견되며 무관한 Skill을 단순 키워드로 추가하지 않는 경계가 생겼다.` |
| `cmp-domain-routing-03` | `context-refactor` | `context-refactor` | `tr-20260911-domain-routing-baseline-03` | `tr-20260911-domain-routing-candidate-03` | `IMPROVED` | `DB backfill·배포 입력에서 data-migration을 주 도메인으로 두고 배포·관측·트랜잭션을 교차 관심사로 제한해 조합한다.` |

## 판정

- `evaluation_result`: `IMPROVED`
- `promotion_recommendation`: `PROMOTE`
- `decision_reason`: `세 비교 쌍이 모두 FAIL에서 PASS로 개선되고 후보 구조 검증과 저장소 필수 검사를 통과했으며 task/evaluator와 권한 경계가 유지돼 저장소 소유자의 명시적 도입 요청으로 0.5.0-domain-skill-routing에 승격했다.`
- `remaining_risks`: `새 Codex 세션의 실제 자동 Skill 선택과 독립 reviewer 검증은 수행하지 않았고 동일 작업자가 candidate 작성과 정적 검토를 겸임했다.`
- `approved_by`: `repository owner`
