# Harness Report 계약

이 디렉터리는 Harness-Diagnostics를 통과한 여러 trace를 집계해 품질·운영 신호를 식별하고, `candidate` 작성 여부를 판단하는 durable report를 관리한다. Report는 개별 작업의 성공 여부를 다시 판정하지 않으며, trace의 `PASS`·`FAIL`·`BLOCKED`를 그대로 집계한다.

## 구현 순서와 진입 조건

Report는 다음 순서에서만 작성한다.

```text
task + evaluator 실행
       ↓
trace 기록
       ↓
Harness-Diagnostics 통과
       ↓
비교 가능한 trace 선택
       ↓
report 집계와 신호 판정
       ↓
필요한 경우 candidate 작성
```

- 입력 trace는 먼저 [`scripts/doctor.sh`](../../scripts/doctor.sh)의 Harness-Diagnostics를 통과해야 한다.
- 동일 baseline 아래의 동일 task·evaluator 또는 같은 개선 목표를 가진 trace를 우선 선택한다.
- candidate 판단용 report는 비교 가능한 trace 3건 이상을 권장한다.
- 3건 미만이거나 통제된 반복 실행이 없으면 report는 작성할 수 있지만 `comparison_readiness`를 `LIMITED`로 기록하고, 그 자체만으로 baseline 변경을 제안하지 않는다.
- 기간, baseline, task 유형 또는 선택 조건이 다른 trace를 합치면 차이를 `limitations`에 명시한다.

## 저장·공유 경계

- 원본 trace는 [trace 보관 정책](../traces/README.md#보관과-git-정책)에 따라 로컬에 두고, report에는 집계에 필요한 비민감 필드와 trace 식별자만 복사한다.
- Report 계약, 템플릿과 완료된 report는 Git으로 관리할 수 있는 공유 산출물이다.
- report를 만들기 전에 원본 trace의 경로·요청·근거를 최소 정보 원칙으로 다시 검토한다.
- 비밀값, 개인정보, 운영 데이터 원문, 절대 사용자 경로, 전체 프롬프트와 긴 명령 출력은 report에 포함하지 않는다.
- report는 source trace가 로컬에서 정리된 뒤에도 판정 근거를 이해할 수 있도록 집계 범위, source inventory, 수치와 한계를 자체 포함한다.
- Diagnostics는 로컬 원본이 있을 때 source inventory와 원문을 대조한다. 원본이 보관 정책에 따라 정리된 뒤에는 원본 부재를 오류로 처리하지 않고, source inventory 내부 참조와 집계 정합성을 검증한다.

## 스키마와 열거값

새 report는 [report-template.md](templates/report-template.md)를 복사해 작성한다. 백틱 필드 키와 표의 구조 식별자는 영문 `snake_case`로 유지하고, 자유 서술은 한국어로 작성한다.

| 필드·용도 | 허용 값 |
|---|---|
| `report_status` | `READY`, `LIMITED`, `BLOCKED` |
| `comparison_readiness` | `READY`, `LIMITED` |
| source 포함 여부 | `INCLUDED`, `EXCLUDED` |
| source 최종 결과 | `PASS`, `FAIL`, `BLOCKED` |
| 신호 상태 | `OPEN`, `RESOLVED`, `INSUFFICIENT_EVIDENCE` |
| 신호 심각도 | `LOW`, `MEDIUM`, `HIGH` |
| `candidate_recommendation` | `CREATE`, `DEFER`, `NONE` |

`report_status`는 report 자체의 완성도를 나타낸다. 입력 trace의 실패가 포함되어도 집계가 완전하면 `READY`일 수 있다. `BLOCKED`는 필수 source 또는 집계 근거가 없어 report를 완성할 수 없을 때만 사용한다.

## 집계 규칙

- `source_trace_count`는 source inventory의 전체 행 수와 일치해야 한다.
- `included_trace_count`와 `excluded_trace_count`의 합은 `source_trace_count`와 일치해야 한다.
- `pass_count`, `fail_count`, `blocked_count`는 `INCLUDED` 행만 집계하며 합이 `included_trace_count`와 일치해야 한다.
- `total_attempt_count`, `total_rework_count`, `unverified_trace_count`, `remaining_risk_trace_count`도 `INCLUDED` 행만 집계한다.
- `unverified` 또는 `remaining_risks`가 `NONE`이 아닌 trace를 각각 한 건으로 센다. 텍스트 항목 수를 세지 않는다.
- 비율은 원시 count와 분모를 함께 표시하며, 표본이 작을 때 백분율만으로 품질 개선을 단정하지 않는다.
- 같은 문제를 표현만 바꿔 여러 신호로 중복 집계하지 않는다.
- 각 signal의 `evidence_trace_ids`는 source inventory에 있는 서로 다른 trace만 참조하며, 그 개수는 `occurrence_count`와 일치해야 한다.

## Candidate 판단

`candidate_recommendation`은 다음 기준으로 기록한다.

- `CREATE`: 동일한 미해결 실패·검증 누락·재작업 원인이 반복되고, 영향을 받는 task와 재평가 방법을 report에서 식별할 수 있다.
- `DEFER`: 신호는 있지만 표본, 비교 가능성 또는 재현 근거가 부족하다.
- `NONE`: 반복되는 미해결 신호가 없거나 이미 현재 baseline·도구에서 해소됐다.

Report는 candidate의 근거이지 변경 승인이 아니다. candidate 구현, 반복 비교 평가와 baseline 승격은 별도 단계로 수행한다.

## 품질 기준

- 모든 source trace가 inventory에 한 번씩만 나타난다.
- 수치 집계가 source inventory와 일치한다.
- 관찰 사실, 해석, candidate 판단과 한계가 분리되어 있다.
- 해결된 과거 문제를 현재 미해결 신호로 보고하지 않는다.
- 서로 다른 task의 단순 합계를 통제된 전후 비교처럼 표현하지 않는다.
- report만으로 source trace 원문이나 민감정보를 복원할 수 없다.

## 디렉터리 구성

```text
.harness/reports/
├── README.md
├── templates/
│   └── report-template.md
└── rp-YYYYMMDD-<slug>-<sequence>.md
```

현재 초기 Harness 구축 trace의 첫 집계는 [rp-20260903-harness-bootstrap-01.md](rp-20260903-harness-bootstrap-01.md)에서 확인한다.
