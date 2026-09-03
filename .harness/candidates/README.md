# Harness Candidate 계약

이 디렉터리는 report에서 반복적으로 확인된 문제를 해결하기 위한 Harness 개선안을 baseline과 분리해 관리한다. Candidate는 현재 실행 기준이 아니며, 대표 task와 evaluator를 사용한 통제된 반복 비교에서 개선이 확인되고 저장소 소유자가 승격을 승인하기 전에는 baseline에 적용하지 않는다.

## 생성 조건

Candidate는 다음 조건을 모두 만족할 때 작성한다.

- source report가 Harness-Diagnostics를 통과했다.
- source report의 `candidate_recommendation`이 `CREATE`다.
- source report의 `comparison_readiness`가 `READY`다.
- 하나 이상의 `OPEN` 신호와 이를 뒷받침하는 trace가 식별됐다.
- 변경할 계약과 영향을 받는 task·evaluator가 구체적이다.
- 동일 입력으로 baseline과 candidate를 비교할 방법이 있다.

`DEFER` 또는 `NONE` report만 존재하면 디렉터리와 템플릿은 유지하되 실제 candidate를 만들지 않는다. 사용자의 명시적 요청만으로 report 근거를 생략하거나 `DEFER`를 `CREATE`로 바꾸지 않는다.

## 평가 격리

- Candidate 내용은 `.harness/candidates/` 안에서만 정의한다.
- candidate 평가 실행에는 확장 trace를 사용하고 `trigger_repeated_evaluation`을 `true`로 기록한다.
- baseline 실행과 candidate 실행은 같은 task, evaluator, 입력, 도구·환경 조건을 사용한다.
- 한 비교 쌍에서는 candidate가 목표로 하는 변경만 달라야 한다.
- candidate를 평가하기 위해 baseline, task 또는 evaluator의 합격 기준을 낮추지 않는다.
- candidate 작성자와 최종 Reviewer·Verifier는 가능하면 분리하고, 분리하지 못하면 독립성 한계를 기록한다.

OpenAI Eval의 데이터 소스와 testing criteria 분리 원칙처럼, 이 계약도 통제 입력과 판정 기준을 candidate 변경에서 분리한다. 저장소의 Markdown candidate는 OpenAI API Eval 객체가 아니며 외부 API 실행을 요구하지 않는다.

## 상태와 판정

| 필드 | 허용 값 |
|---|---|
| `candidate_status` | `DRAFT`, `READY`, `EVALUATING`, `ACCEPTED`, `PROMOTED`, `REJECTED`, `DEFERRED` |
| `evaluation_result` | `PENDING`, `IMPROVED`, `UNCHANGED`, `DEGRADED`, `BLOCKED` |
| `promotion_recommendation` | `PENDING`, `PROMOTE`, `REVISE`, `REJECT` |
| 승격 메타데이터 | `promoted_at`, `promoted_version`, `promotion_trace_id` |

상태 전이는 다음 순서를 따른다.

```text
DRAFT → READY → EVALUATING → ACCEPTED → PROMOTED
                         ├→ REJECTED
                         └→ DEFERRED
```

- `DRAFT`: 근거와 평가 계획을 작성 중이다.
- `READY`: source와 평가 계획이 완전해 반복 비교를 시작할 수 있다.
- `EVALUATING`: 통제된 비교 trace를 수집 중이다.
- `ACCEPTED`: 반복 비교에서 개선이 확인되어 baseline 승격을 제안할 수 있다.
- `PROMOTED`: 저장소 소유자의 승인을 받아 baseline에 반영됐고 승격 시각·버전·trace가 기록됐다.
- `REJECTED`: 효과가 없거나 회귀가 확인되어 승격하지 않는다.
- `DEFERRED`: 환경·표본·검증 제약으로 판정을 미룬다.

`ACCEPTED`는 자동 승격이 아니다. `promotion_recommendation: PROMOTE`와 저장소 소유자의 명시적 승인이 모두 있어야 baseline에 반영하고 버전을 갱신한 뒤 `PROMOTED`로 전이한다. `PROMOTED`가 아닌 candidate의 승격 메타데이터는 모두 `NOT_APPLICABLE`로 기록한다.

## 반복 비교 판정

평가 결과 표의 각 행은 같은 task·evaluator·통제 입력으로 실행한 baseline trace와 candidate trace의 한 비교 쌍이다.

- `IMPROVED`: 기존 실패 또는 품질 문제가 해소되고 다른 성공 조건이 유지됐다.
- `UNCHANGED`: 목표 신호에 유의미한 변화가 없다.
- `DEGRADED`: 기존 통과 항목의 실패, 추가 재작업 또는 새로운 위험이 발생했다.
- `BLOCKED`: 필요한 실행이나 판정을 완료하지 못했다.

`ACCEPTED`와 `PROMOTE`는 모든 필수 비교가 완료되고, 목표 신호가 개선됐으며, 대표 task에서 회귀가 없어야 한다. `UNCHANGED`는 `REVISE` 또는 `REJECT`, `DEGRADED`는 `REJECT`, 불완전한 검증은 `DEFERRED`로 처리한다.

## 저장·보안 경계

- candidate 계약, 템플릿과 완료된 candidate는 Git으로 관리할 수 있다.
- 원본 trace 전체, 긴 명령 출력, 비밀값, 개인정보, 운영 데이터 원문과 절대 사용자 경로를 복사하지 않는다.
- source report·signal ID, 변경 대상, 평가 명령과 trace ID만으로 판단을 재현할 수 있게 기록한다.
- source report가 로컬 trace를 대체하므로 candidate에서 원본 trace의 민감한 내용을 재서술하지 않는다.
- 비교 trace는 평가 중 로컬에 존재해야 하며 candidate trace는 `extended`, `trigger_repeated_evaluation: true`여야 한다. terminal 상태가 된 뒤 원본을 정리해도 report source inventory, 비교 표와 승격 메타데이터의 durable 참조 검증은 유지한다.

## 디렉터리 구성

```text
.harness/candidates/
├── README.md
├── templates/
│   └── candidate-template.md
├── implementations/
│   └── cd-YYYYMMDD-<slug>-<sequence>/
└── cd-YYYYMMDD-<slug>-<sequence>.md
```

새 candidate는 [candidate-template.md](templates/candidate-template.md)를 복사해 작성한다. 실제 candidate 구현은 같은 ID의 `implementations/` 하위 디렉터리에 격리하며, 승인 전에는 baseline 파일에 반영하지 않는다. 첫 승인·승격 기록은 [cd-20260903-report-source-integrity-01.md](cd-20260903-report-source-integrity-01.md)에서 확인한다.
