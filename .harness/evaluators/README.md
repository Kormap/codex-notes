# Harness Evaluators

이 디렉터리는 task의 acceptance criteria를 재현 가능한 근거로 판정하는 evaluator를 정의한다. Evaluator는 구현 방법을 지시하거나 task 범위를 바꾸지 않으며, 통합된 최종 상태를 `PASS`, `FAIL`, `BLOCKED` 중 하나로 판정한다.

## Task 연결

| Evaluator | 연결 task | 핵심 근거 |
|---|---|---|
| [backend-bugfix.md](backend-bugfix.md) | [`backend-bugfix`](../tasks/backend-bugfix.md) | 재현, 회귀 테스트, 관련 build/test, backend 위험 검토 |
| [backend-api-feature.md](backend-api-feature.md) | [`backend-api-feature`](../tasks/backend-api-feature.md) | HTTP 계약, validation·권한, transaction·동시성, 계층별 테스트 |
| [query-performance.md](query-performance.md) | [`query-performance`](../tasks/query-performance.md) | 기준·변경 실행계획, 정합성, 비용 변화, 운영 영향 |
| [frontend-change.md](frontend-change.md) | [`frontend-change`](../tasks/frontend-change.md) | lint/type/test, 상태별 UI, desktop/mobile, console/network |
| [harness-contract.md](harness-contract.md) | [`harness-contract`](../tasks/harness-contract.md) | 결함 재현, 계약 정합성, 회귀 fixture와 전체 Diagnostics |

대표 task에 맞지 않으면 [evaluator-template.md](templates/evaluator-template.md)로 작업별 evaluator를 정의한다. 여러 기술 영역을 변경하면 주 task의 evaluator에 필요한 evaluator를 추가하며, 각각의 필수 검사가 모두 판정되어야 한다.

## 공통 실행 순서

1. 대상 프로젝트 지침, task, acceptance criteria와 고정된 검증 대상을 확인한다.
2. 프로젝트 문서와 기존 스크립트에서 실제 검증 명령을 찾는다.
3. 필수 검사와 조건부 검사를 구분하고, 조건부 검사의 적용 여부를 근거와 함께 확정한다.
4. 통합된 최종 상태에서 비파괴적 검사를 실행한다.
5. 각 검사 결과를 acceptance criterion에 연결하고 전체 판정을 내린다.
6. 정확한 명령 또는 방법, 종료 결과, 미검증 항목과 남은 위험을 trace에 기록한다.

## 명령 선택 규칙

실제 명령은 다음 우선순위로 선택한다.

1. 대상 프로젝트의 `AGENTS.md`, README, CONTRIBUTING 또는 CI가 명시한 명령
2. 저장소에 포함된 wrapper와 task runner: `gradlew`, Maven wrapper, npm scripts 등
3. 동일 모듈에서 이미 사용하는 가장 좁은 테스트·lint·build 명령

문서나 저장소에 없는 명령, profile, database endpoint 또는 test fixture를 추정하지 않는다. 여러 명령이 가능하면 변경 범위를 가장 직접 검증하면서 프로젝트 관례와 일치하는 명령을 선택한다. 선택한 정확한 명령은 evaluator 문서가 아니라 각 trace의 `command_or_method`에 기록한다.

## 판정 규칙

- `PASS`: task의 필수 acceptance criteria와 모든 필수 검사가 충족되었다.
- `FAIL`: 실행 가능한 필수 검사가 실패했거나 acceptance criterion 불충족이 검증 대상의 결함으로 확인되었다.
- `BLOCKED`: 필요한 환경·권한·입력·의존성이 없고 허용된 대체 근거로도 신뢰할 수 있는 판정이 불가능하다.

필수 검사를 실행하지 않았거나 일부 검사만 통과했으면 `PASS`로 판정하지 않는다. 검사 도구 자체의 오류, 기존 실패와 변경으로 생긴 실패를 가능한 범위에서 분리한다. `NOT_APPLICABLE`은 evaluator가 명시한 조건부 검사에만 사용하고 사유를 기록한다.

## 공통 금지 행동

- 테스트, fixture, 구현 또는 설정을 바꿔 평가를 통과시키지 않는다.
- 실패 출력을 숨기거나 종료 코드 하나만으로 전체 결과를 판정하지 않는다.
- acceptance criteria를 평가 중에 축소·삭제하거나 새 성공 조건으로 교체하지 않는다.
- 운영 데이터, 외부 상태 또는 비용에 영향을 주는 검증을 승인 없이 실행하지 않는다.
- Verifier가 구현 변경까지 수행하지 않는다. 변경이 필요하면 Lead에게 `NEEDS_LEAD_DECISION`으로 반환한다.

## 식별자와 Trace 계약

- 파일 이름은 `<evaluator_id>.md`로 한다.
- 검사 항목은 문서 안에서 유일한 `EV-<DOMAIN>-NN` 형식을 사용한다.
- 각 검사에는 연결된 acceptance criterion, 필수 여부, 방법, PASS/FAIL/BLOCKED 조건이 있어야 한다.
- trace의 `evaluator_results`에는 실행한 검사 식별자, 정확한 명령 또는 방법, 판정과 핵심 근거를 행별로 기록한다.
- 여러 검사 결과 중 하나라도 `FAIL`이면 전체 결과는 `FAIL`이다. `FAIL`은 없지만 필수 검사가 `BLOCKED`이면 전체 결과는 `BLOCKED`다.

## 디렉터리 구성

evaluator를 추가하거나 이름을 바꾸면 연결 task와 아래 디렉터리 구성·상단 색인을 함께 갱신한다. [`scripts/doctor.sh`](../../scripts/doctor.sh)는 모든 mapping 행과 task acceptance criteria 연결, ID·파일명·README 색인을 검사한다.

```text
.harness/evaluators/
├── README.md
├── backend-bugfix.md
├── backend-api-feature.md
├── query-performance.md
├── frontend-change.md
├── harness-contract.md
└── templates/
    └── evaluator-template.md
```
