# Context Refactor Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `context-refactor`
- `task_id`: `context-refactor`

## 사전 조건

- [context-refactor task](../tasks/context-refactor.md)의 입력과 비교 기준을 baseline과 후보에 동일하게 적용한다.
- 기준 revision, 후보 snapshot과 세 discovery 조건을 비교 전에 고정한다. 측정 script는 양쪽 지침을 변경하지 않는다.
- 실제 agent 실행이 아닌 문서 계약 검토이며 실행 행동의 동등성까지 증명하지 않는다.
- 문자 수는 [measure-context.py](scripts/measure-context.py)에 대상 snapshot root와 global-only, global-repo 또는 repo-only를 전달해 측정한다. Python 3 표준 라이브러리만 사용한다. 이 도구는 해당 저장소 override의 원본 추가 읽기를 모델링하며 실제 LLM의 지시 이행을 검사하지 않는다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-CTX-01` | `AC-CTX-01` | `REQUIRED` | 전역만 적용·전역과 저장소·전역 없는 clone에서 초기 문서와 원본 추가 읽기를 대조 |
| `EV-CTX-02` | `AC-CTX-02` | `REQUIRED` | 독립 재검토 프롬프트의 모든 시나리오를 기존 위치부터 현재 강제 장치까지 의미 검토 |
| `EV-CTX-03` | `AC-CTX-03` | `REQUIRED` | 동일 측정 방법으로 startup·원본 확보 후 문자 수와 skill metadata를 분리 산정 |
| `EV-CTX-04` | `AC-CTX-04` | `REQUIRED` | 후보의 diff check, doctor, Harness 회귀, 문서 pairing 회귀 및 발견된 설치 결함의 수정 전후 fixture 실행 |
| `EV-CTX-05` | `AC-CTX-05` | `REQUIRED` | 파일 식별자·실행 결과·원본 trace·durable 산출물과 활성 version·승격 상태 대조 |

## 검사별 판정

### `EV-CTX-01`

- `PASS`: 공통 원본을 한 번 확보하고, override나 선택 후 읽기 경로가 명시된다.
- `FAIL`: 공통 원본이 누락되거나 중복 주입된다.
- `BLOCKED`: 입력 지침 또는 discovery 조건을 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-CTX-02`

- `PASS`: 필수 행동, 예외, 복합 검증, 고위험 우선, trace 보관·유출 대응과 승격 경계의 발견 경로가 보존된다.
- `FAIL`: 규칙이 사라지거나 필요한 시점에 발견할 수 없거나 상위 계약을 약화한다.
- `BLOCKED`: 변경 전 문서 또는 이동한 문서가 없어 의미를 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-CTX-03`

- `PASS`: 측정이 재실행 가능하며 실제 tokenizer 측정과 문자 기반 추정을 구분한다. 품질 변화는 baseline과 후보의 수치 차이로 별도 판정한다.
- `FAIL`: README·외부 도구·추가 읽기를 startup 비용과 혼합하거나 실제 감소가 없는 항목을 절감으로 표현한다.
- `BLOCKED`: 측정 대상 또는 환경을 확보하지 못했다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-CTX-04`

- `PASS`: 후보에서 필수 검사가 모두 통과하고 새 결함의 수정 전 실패·수정 후 성공 및 기존 정상·오류 경로가 확인된다. baseline은 당시 기존 검사로 검증하며 새 기능의 검사를 소급 적용하지 않는다.
- `FAIL`: 실행 가능한 필수 검사 또는 지원하는 설치 경로가 실패한다.
- `BLOCKED`: 필수 검사를 실행하지 못했다. 실제 Windows나 독립 LLM 실행을 필수로 지정한 평가라면 그 부재도 BLOCKED다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-CTX-05`

- `PASS`: 실제 근거가 일치하고 미승격 후보의 승인과 version은 변경되지 않았다.
- `FAIL`: snapshot 차이, 허위·사후 왜곡 근거 또는 승인 없는 승격이 있다.
- `BLOCKED`: 필요한 trace·report·snapshot을 확인할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 모든 필수 검사가 PASS다.
- `FAIL`: 하나 이상의 필수 검사가 FAIL이다.
- `BLOCKED`: FAIL은 없지만 필수 검사가 BLOCKED다.

## Trace 반환

- `command_or_method`: `동일 discovery 측정과 시나리오 의미 검토, 대상 저장소의 필수 검사`
- `evidence_summary`: `조건별 초기·추가 읽기와 원본 횟수, 문자 수, 의미 대조 및 종료 코드`
- `unverified`: `실제 Windows·새 agent 실행·tokenizer 등 실행하지 않은 검증과 사유`
- `remaining_risks`: `문서 검토의 행동 증명 한계와 작성자·검토자 독립성 한계`
