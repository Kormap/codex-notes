# Harness Evaluator Template

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `<영문 kebab-case 식별자>`
- `task_id`: `<연결 task 식별자>`

## 사전 조건

- `<고정된 검증 대상, 환경과 필요한 입력>`

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-<DOMAIN>-01` | `AC-<TASK>-01` | `REQUIRED`, `CONDITIONAL` 중 하나 | `<명령 선택 규칙 또는 검토 방법>` |

## 검사별 판정

### `EV-<DOMAIN>-01`

- `PASS`: `<통과 조건>`
- `FAIL`: `<실패 조건>`
- `BLOCKED`: `<판정 불가 조건>`
- `NOT_APPLICABLE`: `<CONDITIONAL 검사에만 허용할 조건 | 허용하지 않음>`

## 전체 판정

- `PASS`: `<필수 성공 조건과 검사 충족 규칙>`
- `FAIL`: `<실패 우선 규칙>`
- `BLOCKED`: `<필수 검사 차단 규칙>`

## Trace 반환

- `command_or_method`: `<실제로 사용한 정확한 명령 또는 방법>`
- `evidence_summary`: `<종료 코드, 핵심 결과와 성공 조건 연결>`
- `unverified`: `<실행하지 못한 검사와 사유 | NONE>`
- `remaining_risks`: `<판정 후 남은 위험 | NONE>`
