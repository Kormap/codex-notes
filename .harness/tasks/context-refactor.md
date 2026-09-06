# Context Refactor Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `context-refactor`
- `task_type`: `code_review`
- `evaluator_id`: `context-refactor`
- `default_trace_level`: `extended`

## 적용 조건

- 전역 지침, 프로젝트 override 또는 조건부 skill·Harness 라우팅의 context 비용과 행동 보존을 반복 비교한다.

## 제외 조건

- 단일 Diagnostics 결함은 harness-contract task를 사용한다. 애플리케이션 구현 성공을 이 task로 대신 판정하지 않는다.

## 필수 입력

- 변경 전 Git revision과 격리된 후보 snapshot 및 파일 식별자
- 비교 전에 고정한 discovery 조건, 필수 규칙 목록과 동일한 evaluator
- 대상 저장소의 필수 검사 명령과 지원 환경

## 범위

### 포함

- 전역만 적용, 전역과 저장소 동시 적용, 전역 설정 없는 clone의 세 discovery 조건
- docs/context-review-prompt.md의 시나리오별 문서 경로·의미·검증·중단 조건 대조
- 설치 회귀 검사와 공유 가능한 비교 근거

### 제외

- 실제 백엔드/Java·프론트엔드/JSP·Vue·인프라 작업을 실행했다고 간주하는 행동
- 승인 전 commit, push, 활성 version 변경 또는 PROMOTED 전이

## 금지 행동

- 이동한 파일의 존재 또는 키워드 일치만으로 의미 보존을 인정하지 않는다.
- README와 선택 후 본문 읽기를 startup 절감에 합산하지 않는다.
- 서로 다른 discovery 조건을 독립적인 LLM 실행 표본 또는 통계적 성능 향상으로 표현하지 않는다.
- 과거 trace·report의 판정과 수치를 현재 결과에 맞게 수정하지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-CTX-01`: 각 discovery 조건에서 공통 원본이 누락되거나 중복 주입되지 않고 startup과 추가 읽기를 구분할 수 있다.
- [ ] `AC-CTX-02`: 필수 규칙의 기존 위치, 현재 위치, 읽는 조건과 검증·중단 경계가 의미상 보존된다.
- [ ] `AC-CTX-03`: 고정된 입력으로 문자 수와 metadata 비용을 측정하고 후보의 감소를 같은 기준으로 설명할 수 있다.
- [ ] `AC-CTX-04`: 후보의 필수 검사와 설치의 정상·오류 경로가 통과하며 미실행 환경은 명시된다.
- [ ] `AC-CTX-05`: snapshot, trace, report, candidate와 사용자 보고가 실제 근거 및 승격 승인 상태와 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `격리된 baseline과 후보의 지침·라우팅·설치 및 비교 산출물`
- `required_evidence`: `세 discovery 조건의 비교 쌍, 파일 식별자, 규칙 이동 대조, 정확한 검증 명령·종료 결과와 환경 한계`
- `allowed_not_applicable`: `NONE`
