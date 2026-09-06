# Codex Harness

Harness는 비단순 개발 작업을 재현 가능한 목표, 검증과 근거로 실행하기 위한 조건부 계약이다. 모든 작업에 자동 적용하지 않는다.

## 런타임 진입점

[`dev-harness`](../skills/dev-harness/SKILL.md)가 작업 수준을 분류하고 필요한 문서만 선택한다. 이 README는 사람용 전체 색인이며 일반 실행에서 전부 읽지 않는다.

| 수준 | 조건 | 로딩 |
|---|---|---|
| 단순 작업 | 강화 조건이 없는 한 줄 수정, 문법 질문, 짧은 읽기 전용 확인 | 공통 지침과 해당 domain skill |
| Harness 작업 | 비단순 구현·리팩터링·설정, 버그 수정, 동작 변경, 재현 가능한 평가·검증 중심 리뷰 | `dev-harness` + baseline + 주 task/evaluator와 필요한 추가 검증 + trace 실행 계약·template |
| 강화 Harness | 고위험, 반복 품질 평가, 멀티·서브에이전트 | Harness 작업 + 확장 trace template + 해당 policy/role |

- 읽기 전용 작업은 사용자가 파일 기록을 요청하거나 승인한 경우에만 trace를 만든다.
- Harness 문서는 사용자 요청, 상위 지침 또는 승인 범위를 확대하지 않는다.
- 조건이 여러 개면 확장 trace 하나에 필요한 근거를 합친다.
- 강화 조건은 단순 작업 예외보다 우선한다.
- report는 집계 시, candidate는 생성·평가·승격 또는 baseline 의미 변경 시에만 읽는다.

## 문서 책임

| Canonical source | 책임과 로딩 조건 |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | 항상 적용할 우선순위, 행동, 검증, 안전과 응답 방식 |
| [`skills/dev-harness/`](../skills/dev-harness/SKILL.md) | 작업 수준과 필요한 Harness 문서 선택 |
| [`baseline/`](baseline/README.md) | 모든 Harness 작업의 공통 실행·검증 계약 |
| [`tasks/`](tasks/README.md) | 선택된 작업의 입력, 범위, 금지 행동과 성공 조건 |
| [`evaluators/`](evaluators/README.md) | 선택된 작업의 검증 방법과 `PASS`·`FAIL`·`BLOCKED` 판정 |
| [`traces/`](traces/README.md) | trace schema, template, 마스킹과 보관 계약 |
| [`traces/runtime.md`](traces/runtime.md) | trace 작성 전 필수 기록·판정·보안 행동 |
| [`maintenance.md`](maintenance.md) | Harness 구조·의미·Diagnostics 변경과 회귀·승격 경계 |
| [`policies/`](policies/README.md) | 고위험·외부 행동·병렬 작업일 때만 적용할 통제 |
| [`roles/`](roles/README.md) | 멀티·서브에이전트에서 실제 배정한 역할 계약 |
| [`reports/`](reports/README.md) | 진단을 통과한 trace 집계와 품질 신호 |
| [`candidates/`](candidates/README.md) | 개선안 비교와 baseline 승격 판단 |

충돌과 적용 순서는 [context contract](baseline/context-contract.md), 고정 용어는 [terminology](baseline/terminology.md), 현재 baseline은 [version](baseline/version.md)을 따른다. Harness-Diagnostics는 [`scripts/doctor.sh`](../scripts/doctor.sh), 회귀 fixture는 [`scripts/test-doctor-harness.sh`](../scripts/test-doctor-harness.sh)에서 관리한다.
