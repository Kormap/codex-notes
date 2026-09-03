# Backend API Feature Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `backend-api-feature`
- `task_type`: `feature`
- `evaluator_id`: `backend-api-feature`
- `default_trace_level`: `minimum`

## 적용 조건

- Java/Spring 등 서버 애플리케이션에 새로운 HTTP API endpoint를 구현한다.
- 요청·응답 계약과 함께 새로운 조회, 생성, 수정, 삭제 또는 업무 동작을 제공한다.

## 제외 조건

- 기존 API의 결함 수정이 주목적이면 [backend-bugfix.md](backend-bugfix.md)를 사용한다.
- SQL 실행계획과 조회 성능 개선이 핵심이면 [query-performance.md](query-performance.md)를 주 task로 사용한다.
- 화면 구현이 주목적이면 [frontend-change.md](frontend-change.md)를 주 task로 사용하고 이 task의 evaluator를 API 변경 검증에 추가한다.

## 필수 입력

- endpoint의 HTTP method와 path
- 요청 field, type, nullability, validation과 기본값
- 정상·실패 응답의 status code, response body와 오류 계약
- 인증·인가, 사용자·tenant·resource 소유권 규칙
- 업무 규칙, 상태 전이와 데이터 정합성 요구사항
- 중복 요청, 동시 실행, 외부 API 호출과 transaction 경계의 적용 여부
- 대상 프로젝트의 package 구조, API 관례, build·test 명령과 현재 작업 트리 상태

API 계약이나 업무 의미가 여러 방향으로 해석되어 호환성, 데이터 또는 보안 결과가 달라지면 구현 전에 사용자에게 확인한다. 프로젝트의 기존 응답 wrapper와 예외 처리 관례는 명시적 변경 요청이 없는 한 유지한다.

## 범위

### 포함

- 요청된 endpoint의 controller, request·response DTO와 validation
- 필요한 application/service, domain과 repository 로직
- 인증·인가, 예외 매핑과 일관된 HTTP 응답
- API 구현에 직접 필요한 최소 설정·문서 변경
- 정상, invalid input, 권한, 상태 전이와 현실적인 실패 경로 테스트

### 제외

- 요청되지 않은 공통 응답 형식, 인증 체계 또는 전체 계층 리팩터링
- 승인되지 않은 DB schema, 외부 API 계약과 운영 데이터 변경
- 무관한 dependency 업그레이드, 포맷 정리와 성능 최적화
- 배포와 운영·스테이징 환경 변경

## 금지 행동

- validation, 권한 또는 resource 소유권 검사를 controller·client 입력 신뢰로 대체하지 않는다.
- domain 규칙과 transaction 경계를 controller에 구현하지 않는다.
- 외부 API 호출을 근거 없이 DB transaction 안에서 수행하거나 실패를 성공 응답으로 숨기지 않는다.
- 동시 요청에 영향을 받는 uniqueness·상태 전이를 사전 조회만으로 보장하지 않는다.
- entity를 API 응답으로 직접 노출하거나 비밀값·개인정보를 로그와 오류 응답에 포함하지 않는다.
- 테스트를 삭제·skip·완화하거나 사용자 변경을 되돌려 통과시키지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-API-01`: HTTP method, path, request·response schema와 정상·실패 status code가 요청 및 기존 API 관례와 일치한다.
- [ ] `AC-API-02`: null, empty, boundary와 invalid input이 정의된 validation·오류 계약으로 거부된다.
- [ ] `AC-API-03`: 인증·인가와 사용자·tenant·resource 소유권 규칙이 적용되거나 공개 API라는 명시적 계약이 있다.
- [ ] `AC-API-04`: 업무 규칙, 상태 전이와 transaction·rollback 경계가 application/domain 계층에서 일관되게 처리된다.
- [ ] `AC-API-05`: 적용되는 중복 요청, 동시성, uniqueness와 외부 API 실패가 DB constraint·lock·idempotency 또는 명시된 실패 정책으로 통제된다.
- [ ] `AC-API-06`: controller와 service 수준의 정상·validation·권한·상태·실패 경로 테스트 중 적용되는 항목이 추가되고 통과한다.
- [ ] `AC-API-07`: 변경 모듈의 관련 test와 build·정적 검사가 통합된 최종 상태에서 통과한다.
- [ ] `AC-API-08`: 로그와 오류 응답은 운영 진단에 필요한 context를 제공하면서 비밀값·개인정보를 노출하지 않는다.
- [ ] `AC-API-09`: 변경 API 계약, 미검증 항목과 남은 운영 위험이 관련 문서·trace·사용자 보고에 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `통합된 최종 working tree의 신규 endpoint, 관련 계층·설정·문서와 테스트`
- `required_evidence`: `API 계약, acceptance criterion별 코드 경로, 실제 test·build 명령과 종료 결과, transaction·권한·동시성·로그 검토`
- `allowed_not_applicable`: `인증·인가, 동시성·idempotency, 외부 API, DB write처럼 endpoint 계약상 존재하지 않는 조건부 위험만 구체적 사유와 함께 허용`
