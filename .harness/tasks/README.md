# Harness Tasks

이 디렉터리는 반복 실행할 대표 작업의 입력, 범위, 금지 행동과 성공 조건을 정의한다. Task는 무엇을 완료해야 하는지 고정하고, 검증 명령과 `PASS`·`FAIL`·`BLOCKED` 판정은 연결된 evaluator에 위임한다.

## 선택과 적용

현재 요청과 가장 가까운 task 하나를 기본으로 선택한다. 여러 작업 유형이 섞이면 사용자 결과를 결정하는 주 task를 하나 선택하고, 추가 검증은 evaluator에서 조합한다. 어느 대표 task에도 맞지 않으면 [task-template.md](templates/task-template.md)로 작업별 task를 작성하거나 trace의 `task_reference`에 현재 요청 식별자를 기록한다.

| 작업 | 적용 조건 | 기본 evaluator |
|---|---|---|
| [backend-bugfix.md](backend-bugfix.md) | Java/Spring 등 서버 코드의 재현 가능한 결함 수정 | [`backend-bugfix`](../evaluators/backend-bugfix.md) |
| [backend-api-feature.md](backend-api-feature.md) | 신규 HTTP API와 관련 비즈니스 동작 구현 | [`backend-api-feature`](../evaluators/backend-api-feature.md) |
| [query-performance.md](query-performance.md) | SQL·인덱스·실행계획의 성능 분석 또는 개선 | [`query-performance`](../evaluators/query-performance.md) |
| [frontend-change.md](frontend-change.md) | Vue·React·JSP/JSTL 화면 또는 브라우저 동작 변경 | [`frontend-change`](../evaluators/frontend-change.md) |
| [harness-contract.md](harness-contract.md) | Harness 문서·Diagnostics 계약의 재현 가능한 결함 수정 | [`harness-contract`](../evaluators/harness-contract.md) |

Task의 기본 범위보다 현재 사용자 요청이나 프로젝트 지침이 더 구체적이면 상위 지침을 따른다. Task를 이유로 요청 범위를 확대하거나 사용자가 제외한 작업을 다시 포함하지 않는다.

## 공통 계약

모든 task 문서는 다음 고정 필드를 포함한다.

- `schema_version`: task 문서 구조 버전
- `task_id`: 저장소 안에서 유일한 영문 kebab-case 식별자
- `task_type`: trace 계약이 허용하는 작업 유형
- `evaluator_id`: 기본 evaluator 식별자
- `default_trace_level`: 기본 trace 수준

각 task는 최소한 다음 내용을 정의한다.

1. 적용 조건과 제외 조건
2. 실행 전에 확보할 입력과 중요한 불확실성
3. 수행 범위와 명시적 제외 범위
4. 금지 행동
5. 검증 가능한 acceptance criteria
6. evaluator에 전달할 변경 상태와 근거

작업 시작 시 문서의 acceptance criteria를 현재 요청에 맞게 구체화할 수 있지만 의미를 약화하거나 이미 실패한 조건을 삭제하지 않는다. 적용되지 않는 조건은 이유와 함께 evaluator 및 trace에 `NOT_APPLICABLE`로 남긴다.

## 식별자와 연결 규칙

- 파일 이름은 `<task_id>.md`로 한다.
- acceptance criteria는 문서 안에서 유일한 `AC-<TASK>-NN` 형식을 사용한다.
- `evaluator_id`는 `.harness/evaluators/<evaluator_id>.md`와 일치해야 한다.
- task의 각 필수 acceptance criterion은 evaluator의 하나 이상의 검사 항목에 연결되어야 한다.
- task는 특정 도구의 성공만을 결과로 정의하지 않는다. 사용자에게 보이는 동작, 정합성 또는 성능 결과를 기준으로 정의한다.

## Task와 Evaluator의 경계

Task는 목표와 허용 범위를 소유한다. Evaluator는 그 목표를 어떤 근거로 판정할지 소유한다.

- Task에서 테스트를 약화하거나 구현을 바꿔 통과시키는 방법을 정의하지 않는다.
- Evaluator에서 작업 범위나 acceptance criteria를 임의로 추가·삭제하지 않는다.
- 실제 실행 명령은 대상 프로젝트의 문서와 기존 스크립트를 우선해 evaluator 실행 시 확정하고 trace에 기록한다.
- 필요한 입력이나 실행 환경이 없어 신뢰할 수 있는 판정이 불가능하면 추정으로 `PASS` 처리하지 않고 `BLOCKED` 근거를 남긴다.

## 디렉터리 구성

task를 추가하거나 이름을 바꾸면 연결 evaluator와 아래 디렉터리 구성·상단 색인을 함께 갱신한다. [`scripts/doctor.sh`](../../scripts/doctor.sh)는 task/evaluator의 ID·파일명·양방향 연결, acceptance criteria mapping과 README 색인을 검사한다.

```text
.harness/tasks/
├── README.md
├── backend-bugfix.md
├── backend-api-feature.md
├── query-performance.md
├── frontend-change.md
├── harness-contract.md
└── templates/
    └── task-template.md
```
