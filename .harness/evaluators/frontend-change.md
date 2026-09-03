# Frontend Change Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `frontend-change`
- `task_id`: `frontend-change`

## 사전 조건

- [frontend-change task](../tasks/frontend-change.md)의 사용자 시나리오, 지원 viewport와 적용 상태가 확정되어 있다.
- 검증 대상은 구현과 테스트가 통합된 최종 working tree와 동일 revision으로 실행한 UI다.
- 프로젝트 지침과 package script에서 lint, type-check, test, dev/build 명령을 선택한다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-FE-01` | `AC-FE-01`, `AC-FE-02` | `REQUIRED` | 상태·event·API 경로 정적 검토와 관련 component/view 테스트 실행 |
| `EV-FE-02` | `AC-FE-03` | `CONDITIONAL` | 비동기 기능에서 중복 제출, stale response, cleanup과 실패 복구 테스트·검토 |
| `EV-FE-03` | `AC-FE-04` | `REQUIRED` | escaping/XSS, label·focus·keyboard와 semantic markup 검토 및 관련 테스트 |
| `EV-FE-04` | `AC-FE-05` | `REQUIRED` | 프로젝트가 제공하는 관련 lint, type-check와 test 명령 실행 |
| `EV-FE-05` | `AC-FE-06` | `CONDITIONAL` | 실행 가능한 UI를 desktop·mobile 대표 viewport에서 핵심·상태별 흐름 검증 |
| `EV-FE-06` | `AC-FE-06` | `CONDITIONAL` | 브라우저 console error와 실패한 network 요청 확인 |
| `EV-FE-07` | `AC-FE-07` | `REQUIRED` | 미검증 브라우저·환경과 trace·사용자 보고 대조 |

## 검사별 판정

### `EV-FE-01` 사용자 흐름과 상태

- `PASS`: 핵심 시나리오와 적용되는 loading·empty·error·validation·disabled 상태가 기대 전이와 결과를 가진다.
- `FAIL`: 필수 흐름이 동작하지 않거나 상태가 누락·모순된다.
- `BLOCKED`: API 계약, fixture 또는 상태 진입 방법이 없어 필수 동작을 판정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다. 존재하지 않는 개별 상태만 사유와 함께 제외할 수 있다.

### `EV-FE-02` 비동기 정합성

- `PASS`: 적용되는 비동기 위험이 코드와 테스트 또는 재현 가능한 브라우저 근거로 통제된다.
- `FAIL`: 중복 요청, 오래된 응답 반영, unmount 후 갱신 또는 실패 상태 불일치가 재현된다.
- `BLOCKED`: 비동기 상태를 재현할 수 없어 필수 위험을 판정할 수 없다.
- `NOT_APPLICABLE`: network·timer·비동기 event가 없는 순수 정적 화면일 때만 허용한다.

### `EV-FE-03` 보안과 접근성

- `PASS`: 신뢰되지 않은 값이 안전하게 출력되고 핵심 조작에 label, focus, keyboard와 semantic 동작이 유지된다.
- `FAIL`: XSS 가능한 출력, 접근 불가능한 필수 control 또는 focus 손실이 있다.
- `BLOCKED`: server rendering 또는 sanitization 경로를 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-FE-04` 정적 검사와 테스트

- `PASS`: 변경 범위에 관련된 lint, type-check와 테스트가 모두 통과한다. 프로젝트가 특정 검사를 제공하지 않으면 부재 근거를 남기고 나머지 검사를 실행한다.
- `FAIL`: 실행 가능한 검사 실패가 변경으로 발생했거나 필수 테스트가 기대 동작을 검증하지 않는다.
- `BLOCKED`: 프로젝트가 요구하는 필수 검사를 환경·의존성 문제로 실행할 수 없다.
- `NOT_APPLICABLE`: evaluator 전체에는 허용하지 않는다. 개별 도구가 프로젝트에 없다는 사실만 근거로 남길 수 있다.

### `EV-FE-05` 실제 브라우저 흐름

- `PASS`: desktop·mobile 대표 viewport에서 핵심 흐름과 적용 상태가 시각·기능적으로 정상이다.
- `FAIL`: 레이아웃 파손, 잘림, 조작 불가 또는 상태별 동작 오류가 재현된다.
- `BLOCKED`: 실행 가능한 UI지만 서버·브라우저·fixture 제약으로 확인할 수 없다.
- `NOT_APPLICABLE`: 문서·정적 asset처럼 실행할 사용자 UI가 없는 변경에만 허용한다.

### `EV-FE-06` Console과 Network

- `PASS`: 검증 흐름에서 변경 관련 console error와 의도하지 않은 실패 요청이 없다.
- `FAIL`: 변경으로 발생한 console error, 반복·중복 요청 또는 실패한 필수 요청이 있다.
- `BLOCKED`: 실행 가능한 UI지만 console·network 상태를 확인할 수 없다.
- `NOT_APPLICABLE`: `EV-FE-05`가 정당하게 `NOT_APPLICABLE`인 경우에만 허용한다.

### `EV-FE-07` 보고 정합성

- `PASS`: 실행하지 못한 viewport·브라우저·상태와 남은 위험이 trace와 사용자 보고에 일치한다.
- `FAIL`: 실패나 미검증 상태를 누락하거나 실제 브라우저 검증 없이 완료로 표현한다.
- `BLOCKED`: 최종 trace 또는 사용자 보고 초안이 없어 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 모든 `REQUIRED` 검사와 적용되는 `CONDITIONAL` 검사가 `PASS`다.
- `FAIL`: 하나 이상의 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 또는 적용되는 조건부 검사가 `BLOCKED`다.

## Trace 반환

정확한 lint·type-check·test 명령과 종료 결과, 검증 URL 대신 공개 가능한 화면 식별자, viewport, 상태별 결과, console·network 요약을 기록한다. screenshot에 민감정보가 있으면 trace에 첨부하지 않고 마스킹된 결과만 기록한다.
