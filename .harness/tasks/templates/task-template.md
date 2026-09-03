# Harness Task Template

## 메타데이터

- `schema_version`: `1`
- `task_id`: `<영문 kebab-case 식별자>`
- `task_type`: `bug_fix | feature | behavior_change | repeated_work | code_review | other`
- `evaluator_id`: `<연결할 evaluator 식별자>`
- `default_trace_level`: `minimum | extended`

## 적용 조건

- `<이 task를 선택하는 조건>`

## 제외 조건

- `<다른 task를 선택해야 하는 조건 | NONE>`

## 필수 입력

- `<실행 전에 확보할 입력과 근거>`

## 범위

### 포함

- `<수행할 범위>`

### 제외

- `<수행하지 않을 범위 | NONE>`

## 금지 행동

- `<범위를 벗어나거나 판정을 왜곡하는 행동>`

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-<TASK>-01`: `<관찰·검증 가능한 결과>`
- [ ] `AC-<TASK>-02`: `<관찰·검증 가능한 결과>`

## Evaluator 전달 계약

- `evaluation_target`: `<검증할 변경 상태 또는 산출물>`
- `required_evidence`: `<성공 조건 판정에 필요한 근거>`
- `allowed_not_applicable`: `<조건부 항목과 NOT_APPLICABLE 사유 | NONE>`
