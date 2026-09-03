# Frontend Change Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `frontend-change`
- `task_type`: `behavior_change`
- `evaluator_id`: `frontend-change`
- `default_trace_level`: `minimum`

## 적용 조건

- Vue, React, JSP/JSTL, CSS 또는 브라우저 JavaScript의 사용자 동작이나 화면을 변경한다.
- API 연동 상태, 반응형 배치 또는 브라우저 상호작용 검증이 필요하다.

## 제외 조건

- 서버 API와 비즈니스 규칙 변경이 주목적이면 해당 backend task를 주 task로 선택하고 이 task의 evaluator만 추가한다.
- 시각 동작이 없는 문구 오탈자나 단순 정적 설정은 Harness task를 만들지 않는다.

## 필수 입력

- 사용자 시나리오와 기대 화면·동작
- 대상 framework, build 도구, 지원 브라우저와 viewport
- API 요청·응답 계약과 loading, empty, error, validation, disabled 상태
- 기존 디자인 시스템·컴포넌트 관례와 실행 방법

디자인 또는 API 의미가 여러 방향으로 해석되어 결과가 달라지면 구현 전에 사용자 확인을 받는다. 사소한 배치 선택은 기존 화면 관례를 따른다.

## 범위

### 포함

- 요청된 화면과 사용자 상호작용의 최소 구현
- 관련 상태·event·API 연결과 실패 처리
- 사용자 입력 escaping, XSS와 중복 제출 방지
- 관련 lint, type-check, test와 실제 브라우저 검증

### 제외

- 요청되지 않은 전역 디자인 개편과 공통 컴포넌트 재작성
- 승인되지 않은 backend API 계약 변경
- 무관한 dependency 업그레이드와 자동 포맷팅

## 금지 행동

- loading, error 또는 validation 실패를 성공 상태처럼 숨기지 않는다.
- 비동기 요청의 stale response, 중복 제출, cleanup 또는 실패한 optimistic update를 무시하지 않는다.
- JSP/JSTL 출력 escaping을 약화하거나 신뢰되지 않은 HTML을 그대로 렌더링하지 않는다.
- 테스트·type 오류를 skip 또는 설정 완화로 통과시키지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-FE-01`: 요청된 사용자 시나리오가 기대 상태 전이와 결과를 제공한다.
- [ ] `AC-FE-02`: loading, empty, error, validation과 disabled 상태 중 적용되는 상태가 올바르게 표시되고 조작된다.
- [ ] `AC-FE-03`: 비동기 흐름의 중복 제출, stale response, cleanup과 실패 복구 중 적용되는 위험이 처리된다.
- [ ] `AC-FE-04`: 신뢰되지 않은 입력·출력의 escaping과 접근성 기본 동작이 유지된다.
- [ ] `AC-FE-05`: 관련 lint, type-check와 테스트가 최종 상태에서 통과한다.
- [ ] `AC-FE-06`: 실행 가능한 UI는 desktop·mobile 대표 viewport에서 핵심 흐름을 확인하고 console 오류와 실패한 network 요청이 없다.
- [ ] `AC-FE-07`: 실행하지 못한 브라우저·환경 검증과 남은 위험이 trace와 사용자 보고에 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `통합된 최종 working tree의 frontend 변경과 실행 중인 대표 화면`
- `required_evidence`: `상태별 결과, 실제 lint·type-check·test 명령, desktop·mobile 브라우저 결과, console·network 확인`
- `allowed_not_applicable`: `특정 상태 또는 비동기 위험이 기능 계약상 존재하지 않을 때만 해당 항목을 사유와 함께 NOT_APPLICABLE 처리`
