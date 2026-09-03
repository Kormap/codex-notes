# Backend API Feature Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `backend-api-feature`
- `task_id`: `backend-api-feature`

## 사전 조건

- [backend-api-feature task](../tasks/backend-api-feature.md)의 API 계약, 업무 규칙, 조건부 위험과 acceptance criteria가 현재 요청에 맞게 확정되어 있다.
- 검증 대상은 endpoint, 관련 application/domain/persistence 변경과 테스트가 통합된 최종 working tree로 고정한다.
- 프로젝트 지침과 기존 build/test 경로를 확인하고 [공통 명령 선택 규칙](README.md#명령-선택-규칙)으로 실제 명령을 정한다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-API-01` | `AC-API-01` | `REQUIRED` | controller/API 테스트와 정적 검토로 method, path, schema, content type과 status code 대조 |
| `EV-API-02` | `AC-API-02` | `REQUIRED` | null, empty, boundary, malformed와 업무상 invalid input 테스트 |
| `EV-API-03` | `AC-API-03` | `REQUIRED` | 인증 누락, 권한 부족, 다른 사용자·tenant·resource 접근 테스트 또는 공개 API 계약 검토 |
| `EV-API-04` | `AC-API-04` | `REQUIRED` | service/domain 테스트와 호출 경로로 업무 규칙, 상태 전이, transaction과 rollback 대조 |
| `EV-API-05` | `AC-API-05` | `CONDITIONAL` | write·외부 연계 API의 중복·동시 요청, constraint·lock·idempotency와 외부 실패 정책 테스트·검토 |
| `EV-API-06` | `AC-API-06` | `REQUIRED` | endpoint와 service의 적용 가능한 정상·실패 경로 테스트 coverage 검토 및 실행 |
| `EV-API-07` | `AC-API-07` | `REQUIRED` | 변경 모듈의 관련 test suite와 build·정적 검사 실행 |
| `EV-API-08` | `AC-API-08` | `REQUIRED` | 로그 context, 예외 매핑, 오류 응답과 민감정보 노출 정적 검토 |
| `EV-API-09` | `AC-API-09` | `REQUIRED` | API 문서, 실제 검증 결과, 미검증 항목·남은 위험과 trace·사용자 보고 대조 |

## 검사별 판정

### `EV-API-01` HTTP 계약

- `PASS`: endpoint의 method, path, request·response schema, content type과 정상·실패 status가 확정 계약 및 프로젝트 관례와 일치한다.
- `FAIL`: endpoint 계약이 요청과 다르거나 오류를 성공 status로 반환하는 등 HTTP 의미가 불일치한다.
- `BLOCKED`: API 계약 또는 실행·테스트 경로가 없어 신뢰성 있게 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-02` 입력 검증

- `PASS`: 적용되는 null, empty, boundary, malformed와 업무상 invalid 입력이 일관된 오류 계약으로 거부된다.
- `FAIL`: invalid 입력이 처리되거나 예상하지 못한 5xx·내부 정보 노출을 발생시킨다.
- `BLOCKED`: 요청 schema나 validation 규칙을 확정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-03` 인증·인가와 소유권

- `PASS`: 인증·인가와 소유권 경계가 코드와 테스트에 반영되었거나 공개 API라는 계약과 노출 범위가 명시되어 있다.
- `FAIL`: 권한 없는 주체가 endpoint 또는 다른 주체의 resource에 접근·변경할 수 있다.
- `BLOCKED`: 보안 정책, principal 또는 tenant 경계를 확인할 수 없다.
- `NOT_APPLICABLE`: 별도 값으로 제외하지 않는다. 공개 API도 명시적 계약을 근거로 `PASS` 판정한다.

### `EV-API-04` 업무 규칙과 Transaction

- `PASS`: 업무 규칙과 상태 전이가 적절한 계층에 있고 성공·실패 시 commit·rollback 결과가 계약과 일치한다. 읽기 전용 API는 read transaction과 조회 일관성이 적절하다.
- `FAIL`: partial write, 잘못된 propagation, controller의 업무 로직 또는 예외에 따른 정합성 손상이 있다.
- `BLOCKED`: persistence·transaction 경로나 실패 시 기대 상태를 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-05` 동시성·중복·외부 실패

- `PASS`: 적용되는 경쟁 조건과 외부 실패가 constraint, lock, idempotency, timeout·retry 또는 명시된 실패 정책으로 통제되고 테스트·근거가 있다.
- `FAIL`: 사전 조회만으로 uniqueness를 보장하거나 중복 상태 전이, 무제한 retry, transaction 안의 장시간 외부 호출 등 현실적인 장애 경로가 남아 있다.
- `BLOCKED`: 적용되는 위험이 있지만 동시성·외부 실패 조건을 재현하거나 구조적으로 판정할 수 없다.
- `NOT_APPLICABLE`: read-only이면서 외부 호출·중복 처리·경쟁 상태가 없는 endpoint에만 허용한다.

### `EV-API-06` 계층별 기능 테스트

- `PASS`: controller와 service의 적용 가능한 정상·validation·권한·상태·실패 경로가 assertion으로 검증되고 관련 테스트가 통과한다.
- `FAIL`: 필수 경로 테스트가 누락되었거나 테스트가 실제 계약을 검증하지 않거나 실패한다.
- `BLOCKED`: 테스트 인프라·fixture·의존성 문제로 필수 기능 테스트를 실행할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-07` 모듈 검증

- `PASS`: 프로젝트가 요구하는 관련 test suite, build와 정적 검사가 통과한다. 별도 정적 검사가 없으면 부재 근거를 남긴다.
- `FAIL`: 실행 가능한 검사가 변경으로 인해 실패한다.
- `BLOCKED`: 프로젝트 필수 검사를 환경·권한·의존성 문제로 실행할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-08` 오류와 로그

- `PASS`: 예외가 일관된 오류 계약으로 매핑되고 운영 진단 context가 있으면서 비밀값·개인정보·내부 구현을 노출하지 않는다.
- `FAIL`: 예외 은닉, 무조건 성공 응답, stack trace·민감정보 노출 또는 진단 불가능한 실패 경로가 있다.
- `BLOCKED`: 공통 예외 처리나 logging 설정을 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-API-09` 문서와 보고 정합성

- `PASS`: API 계약 변경이 기존 문서 관례에 반영되고 미검증 항목과 남은 위험이 실제 결과, trace와 사용자 보고에 일치한다. API 문서 체계가 없는 프로젝트는 그 사실과 계약을 trace·사용자 보고에 기록한다.
- `FAIL`: 문서화가 필요한 공개 계약이 누락되거나 실패·미검증·운영 위험을 완료로 표현한다.
- `BLOCKED`: 관련 문서 관례, 최종 trace 또는 사용자 보고 초안이 없어 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 모든 `REQUIRED` 검사가 `PASS`이고 적용되는 `CONDITIONAL` 검사도 `PASS`다.
- `FAIL`: 하나 이상의 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 또는 적용되는 조건부 검사가 `BLOCKED`다.

## Trace 반환

각 검사마다 실제 명령 또는 검토 방법, 종료 코드, 핵심 결과와 연결된 acceptance criterion을 기록한다. endpoint 예시에는 민감한 요청·응답 원문을 복사하지 않고 method, path template, status와 비식별 schema만 남긴다.
