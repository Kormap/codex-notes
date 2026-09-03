# Backend Bug Fix Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `backend-bugfix`
- `task_type`: `bug_fix`
- `evaluator_id`: `backend-bugfix`
- `default_trace_level`: `minimum`

## 적용 조건

- Java/Spring API, service, repository 또는 서버 측 로직의 실제 동작이 기대 결과와 다르다.
- 실패 경로를 코드, 테스트, 로그 또는 재현 절차로 특정할 수 있다.

## 제외 조건

- 신규 기능이 주목적이면 현재 요청에 맞는 별도 feature task를 사용한다.
- SQL 실행계획과 조회 성능 개선이 핵심이면 [query-performance.md](query-performance.md)를 사용한다.
- 화면 또는 브라우저 동작이 핵심이면 [frontend-change.md](frontend-change.md)를 사용한다.

## 필수 입력

- 기대 동작과 실제 동작의 차이
- 재현 입력, 실패 테스트, 로그 또는 코드 경로 중 하나 이상의 근거
- 영향받는 API·도메인 상태·데이터 범위
- 대상 프로젝트의 빌드·테스트 지침과 현재 작업 트리 상태

원인이 불명확하면 구현 전에 재현과 읽기 전용 조사를 우선한다. 데이터 의미, 외부 계약, 보안 또는 운영 동작을 바꾸는 결정은 사용자 확인 없이 추정하지 않는다.

## 범위

### 포함

- 결함의 재현과 원인 규명
- 원인을 제거하는 최소 코드·설정 변경
- 현실적인 실패·경계 경로를 포함한 가장 작은 회귀 테스트
- 변경 경로에 직접 연결된 문서 또는 설정 갱신

### 제외

- 결함과 무관한 리팩터링, 포맷 정리와 의존성 업그레이드
- 승인되지 않은 API·DB schema·외부 시스템 계약 변경
- 운영·스테이징 데이터 수정과 배포

## 금지 행동

- 테스트를 삭제·skip·완화하거나 기대값을 결함 동작에 맞춰 통과시키지 않는다.
- 넓은 예외 처리, 무조건 성공 응답 또는 임의 기본값으로 원인을 숨기지 않는다.
- 필요 근거 없이 transaction 범위를 넓히거나 외부 API 호출을 transaction 안으로 이동하지 않는다.
- 사용자 변경을 되돌리거나 요청과 무관한 코드를 함께 정리하지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-BEBUG-01`: 기대 동작, 실제 동작과 원인이 동일한 실행 경로의 근거로 연결된다.
- [ ] `AC-BEBUG-02`: 수정 전 결함을 재현하는 테스트가 추가되거나, 테스트가 현실적으로 불가능한 사유와 대체 재현 근거가 기록된다.
- [ ] `AC-BEBUG-03`: 변경은 확인된 원인을 제거하는 최소 범위이며 기존 API·데이터 계약을 불필요하게 바꾸지 않는다.
- [ ] `AC-BEBUG-04`: 회귀 테스트와 변경 모듈의 관련 테스트가 통합된 최종 상태에서 통과한다.
- [ ] `AC-BEBUG-05`: transaction, rollback, 동시성, 예외 처리와 로그에 새 회귀가 없다는 검토 근거가 있다.
- [ ] `AC-BEBUG-06`: 미검증 항목과 남은 운영 위험이 trace와 사용자 보고에 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `통합된 최종 working tree의 backend 변경과 관련 테스트`
- `required_evidence`: `재현 근거, 원인-변경 연결, 실제 테스트 명령·종료 결과, diff 검토 결과`
- `allowed_not_applicable`: `AC-BEBUG-02의 수정 전 자동 테스트만 테스트 인프라 또는 재현 가능성 제약이 입증된 경우 허용`
