# Harness Contract Bug Fix Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `harness-contract`
- `task_type`: `bug_fix`
- `evaluator_id`: `harness-contract`
- `default_trace_level`: `extended`

## 적용 조건

- Harness 문서, trace, report, candidate 또는 Diagnostics의 실제 판정이 명시된 계약과 다르다.
- 동일한 입력과 환경에서 기대 판정과 실제 판정의 차이를 재현할 수 있다.

## 제외 조건

- Java/Spring 서버 동작, SQL 성능 또는 브라우저 UI가 결함의 주 대상이면 해당 전용 task를 사용한다.

## 필수 입력

- 기대 판정과 실제 판정의 차이
- 최소 재현 fixture 또는 동일 검사 경로의 대체 근거
- 변경할 Harness 계약과 영향을 받는 산출물
- baseline과 candidate에 동일하게 적용할 명령·환경

## 범위

### 포함

- Harness 계약 결함의 재현과 원인 규명
- 원인을 제거하는 최소 문서·스크립트 변경
- 정상 상태와 결함 입력을 함께 검증하는 회귀 fixture
- report·candidate·trace의 참조 및 판정 정합성 확인

### 제외

- 결함과 무관한 Harness 재설계
- 합격 기준 완화 또는 기존 trace·report 근거의 사후 왜곡
- 승인 전 candidate의 baseline 승격

## 금지 행동

- fixture를 기대 결함에 맞춰 약화하거나 실패 출력을 숨기지 않는다.
- 통제 입력, evaluator 또는 합격 기준을 baseline과 candidate 사이에서 바꾸지 않는다.
- candidate 평가 중 baseline 파일을 직접 수정하지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-HARNESS-01`: 기대 판정과 실제 판정의 차이가 최소 fixture로 반복 재현된다.
- [ ] `AC-HARNESS-02`: 변경이 확인된 원인만 제거하고 기존 Harness 계약을 불필요하게 바꾸지 않는다.
- [ ] `AC-HARNESS-03`: 같은 입력에서 candidate가 결함을 탐지하고 baseline은 놓치는 비교 근거가 있다.
- [ ] `AC-HARNESS-04`: 정상 fixture와 기존 전체 Harness 회귀 검사가 candidate에서 유지된다.
- [ ] `AC-HARNESS-05`: trace, report, candidate 상태와 사용자 보고가 실제 검증 결과와 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `격리된 candidate 구현과 동일 입력의 baseline/candidate 비교 결과`
- `required_evidence`: `3개 이상의 비교 가능한 trace, 재현 명령·종료 결과, 회귀 suite, 최종 diff와 남은 위험`
- `allowed_not_applicable`: `NONE`
