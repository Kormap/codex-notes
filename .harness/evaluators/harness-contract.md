# Harness Contract Bug Fix Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `harness-contract`
- `task_id`: `harness-contract`

## 사전 조건

- [harness-contract task](../tasks/harness-contract.md)의 기대·실제 판정과 통제 입력이 고정되어 있다.
- candidate 구현은 baseline과 분리되어 있고 비교 시 변경 대상 외 입력·환경·합격 기준이 같다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-HARNESS-01` | `AC-HARNESS-01` | `REQUIRED` | 최소 fixture를 baseline에서 3회 이상 실행해 동일 진단 누락 재현 |
| `EV-HARNESS-02` | `AC-HARNESS-02`, `AC-HARNESS-03` | `REQUIRED` | 동일 fixture의 baseline/candidate 결과와 구현 diff를 대조 |
| `EV-HARNESS-03` | `AC-HARNESS-04` | `REQUIRED` | candidate에서 정상 repository doctor와 전체 회귀 fixture 실행 |
| `EV-HARNESS-04` | `AC-HARNESS-05` | `REQUIRED` | trace·report·candidate의 수치, 참조, 상태와 실제 결과 대조 |

## 검사별 판정

### `EV-HARNESS-01`

- `PASS`: 최소 3개의 비교 가능한 입력에서 같은 계약 위반을 baseline이 놓친다.
- `FAIL`: 누락이 재현되지 않거나 서로 다른 원인이라 반복 신호로 볼 수 없다.
- `BLOCKED`: baseline 또는 fixture를 동일 조건으로 실행할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-HARNESS-02`

- `PASS`: candidate만 모든 통제 입력의 계약 위반을 탐지하고 변경이 확인된 원인에 한정된다.
- `FAIL`: candidate가 입력을 놓치거나 baseline과 조건이 다르거나 범위 밖 변경이 있다.
- `BLOCKED`: 격리된 candidate 실행 또는 결과 대조가 불가능하다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-HARNESS-03`

- `PASS`: 정상 repository doctor와 기존 전체 회귀 fixture가 candidate에서 종료 코드 0으로 통과한다.
- `FAIL`: 기존 정상 입력이 실패하거나 회귀 fixture에 새 실패가 발생한다.
- `BLOCKED`: 필수 검사를 실행할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-HARNESS-04`

- `PASS`: 기록된 trace·report·candidate가 실제 명령 결과와 일치하고 참조·집계 검사를 통과한다.
- `FAIL`: 결과, 수치, 상태 또는 참조가 실제 근거와 다르다.
- `BLOCKED`: 최종 산출물이 없어 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 네 필수 검사가 모두 `PASS`다.
- `FAIL`: 하나 이상의 필수 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 검사가 `BLOCKED`다.

## Trace 반환

- `command_or_method`: `격리 HOME을 사용한 baseline/candidate fixture 비교와 전체 doctor 회귀 명령`
- `evidence_summary`: `각 입력의 종료 코드, 기대 진단 문구, 전체 회귀 결과와 성공 조건 연결`
- `unverified`: `실행하지 못한 환경·검사와 사유 또는 NONE`
- `remaining_risks`: `정적 Markdown 파서가 확인하지 못하는 의미 수준의 불일치 또는 NONE`
