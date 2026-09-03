# Backend Bug Fix Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `backend-bugfix`
- `task_id`: `backend-bugfix`

## 사전 조건

- [backend-bugfix task](../tasks/backend-bugfix.md)의 기대·실제 동작, 변경 범위와 acceptance criteria가 현재 요청에 맞게 확정되어 있다.
- 검증 대상은 구현과 테스트가 통합된 최종 working tree로 고정한다.
- 프로젝트 지침과 기존 build/test 경로를 확인하고 [공통 명령 선택 규칙](README.md#명령-선택-규칙)으로 실제 명령을 정한다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-BEBUG-01` | `AC-BEBUG-01`, `AC-BEBUG-02` | `REQUIRED` | 실패 테스트, 안전한 재현 절차 또는 동일 코드 경로의 대체 근거로 결함과 원인을 대조 |
| `EV-BEBUG-02` | `AC-BEBUG-03` | `REQUIRED` | 최종 diff와 호출 경로를 검토해 원인-변경 연결, API·데이터 계약과 변경 범위 확인 |
| `EV-BEBUG-03` | `AC-BEBUG-04` | `REQUIRED` | 새 회귀 테스트와 변경 모듈의 가장 좁은 관련 test suite 실행 |
| `EV-BEBUG-04` | `AC-BEBUG-04` | `CONDITIONAL` | 프로젝트가 분리 제공하는 compile, build, lint 또는 static analysis 실행 |
| `EV-BEBUG-05` | `AC-BEBUG-05` | `REQUIRED` | transaction, rollback, 외부 호출, 동시성, 예외 처리와 로그의 변경 전후 정적 검토 |
| `EV-BEBUG-06` | `AC-BEBUG-06` | `REQUIRED` | 실제 미검증 항목·남은 위험과 trace·사용자 보고 대조 |

## 검사별 판정

### `EV-BEBUG-01` 재현과 원인

- `PASS`: 수정 전 결함을 재현하는 테스트가 있거나, 자동 테스트가 현실적으로 불가능한 이유와 동일 경로의 대체 재현 근거가 있고 원인이 설명된다.
- `FAIL`: 재현 결과가 요청된 결함과 다르거나 변경이 확인된 원인을 다루지 않는다.
- `BLOCKED`: 필요한 입력·환경이 없어 결함과 원인을 신뢰성 있게 특정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다. 자동 테스트만 task의 허용 조건에 따라 대체 근거로 바꿀 수 있다.

### `EV-BEBUG-02` 변경 범위

- `PASS`: 모든 변경 라인이 확인된 원인 또는 필요한 회귀 테스트에 연결되고 불필요한 계약 변경이 없다.
- `FAIL`: 관련 없는 리팩터링, 승인되지 않은 계약 변경 또는 원인을 숨기는 우회가 있다.
- `BLOCKED`: 기준 diff나 영향 계약을 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-BEBUG-03` 회귀·관련 테스트

- `PASS`: 선택한 회귀 테스트와 관련 suite가 종료 코드 0으로 통과하고 핵심 assertion이 기대 동작을 검증한다.
- `FAIL`: 테스트 실패가 재현되며 변경 대상의 결함이거나 테스트가 기대 동작을 검증하지 않는다.
- `BLOCKED`: 의존성·환경·권한 문제로 필수 테스트를 실행할 수 없고 안전한 대체 검증이 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-BEBUG-04` 추가 build·정적 검사

- `PASS`: 프로젝트가 요구하거나 변경 경로에 필요한 추가 검사가 통과한다.
- `FAIL`: 추가 검사의 실패가 변경으로 발생했다.
- `BLOCKED`: 필수로 선택된 추가 검사가 환경 문제로 실행되지 않는다.
- `NOT_APPLICABLE`: 프로젝트가 별도 검사를 제공하지 않고 `EV-BEBUG-03`이 필요한 compile을 포함할 때만 허용한다.

### `EV-BEBUG-05` Backend 위험 검토

- `PASS`: 변경된 경로에서 transaction·동시성·예외·로그 위험이 없거나 필요한 통제가 코드와 테스트에 반영되어 있다.
- `FAIL`: rollback 누락, race condition, 외부 호출 중 connection 점유, 예외 은닉 또는 민감정보 로그 같은 현실적 회귀가 있다.
- `BLOCKED`: 변경 경로나 관련 설정을 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-BEBUG-06` 보고 정합성

- `PASS`: 미검증 항목과 남은 위험이 실제 결과, trace와 사용자 보고에 동일하게 반영된다.
- `FAIL`: 실패·미실행 검사 또는 현실적인 남은 위험이 누락되거나 통과로 표현된다.
- `BLOCKED`: 최종 trace 또는 사용자 보고 초안이 없어 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 모든 `REQUIRED` 검사가 `PASS`이고 적용되는 `CONDITIONAL` 검사도 `PASS`다.
- `FAIL`: 하나 이상의 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 검사가 `BLOCKED`다.

## Trace 반환

각 검사마다 실제 명령 또는 검토 방법, 종료 코드, 핵심 결과와 연결된 acceptance criterion을 기록한다. 기존 실패는 변경으로 발생한 실패와 분리하고, 분리할 수 없으면 그 한계를 `unverified`와 `remaining_risks`에 남긴다.
