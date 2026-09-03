# Harness Trace 계약

이 디렉터리는 Harness 작업의 입력, 실행, 검증과 결과를 Meta-Harness가 비교할 수 있는 구조화된 증거로 남기는 계약과 템플릿을 관리한다. Trace는 전체 대화나 명령 로그의 복사본이 아니며, 작업 판정과 개선에 필요한 최소 근거만 기록한다.

## 적용 수준

| 조건 | 사용할 템플릿 | 필수 내용 |
|---|---|---|
| 일반 Harness 작업 | [minimum-trace.md](templates/minimum-trace.md) | task, 성공 조건, 변경 범위, evaluator 결과, 재작업, 검증 한계, 남은 위험, Skill |
| 고위험 작업 | [extended-trace.md](templates/extended-trace.md) | 최소 trace + 위험, 승인, 외부 행동, 실패·복구 판단 |
| 반복 품질 평가 | [extended-trace.md](templates/extended-trace.md) | 최소 trace + 실행 식별자, 비교 대상, 동일 evaluator 결과, 품질 변화 |
| 멀티·서브에이전트 작업 | [extended-trace.md](templates/extended-trace.md) | 최소 trace + 역할, 위임, 파일 소유권, 역할별 결과, 통합 검증 |

강화 조건이 여러 개면 하나의 확장 trace에 해당 섹션을 모두 작성한다. 적용되지 않는 확장 섹션은 `NOT_APPLICABLE`로 표시하며 삭제하지 않는다. 단순 작업은 trace를 만들지 않는다.

## Meta-Harness·Harness-Diagnostics 호환 계약

Trace는 사람이 읽는 Markdown 문서이면서 Meta-Harness와 Harness-Diagnostics가 검사할 구조화된 입력이다. 두 목적을 섞지 않도록 다음 경계를 지킨다.

- 문서 제목, 섹션명, 표의 표시 문구와 설명은 저장소 기본 언어인 한국어를 사용한다.
- 백틱으로 표시한 필드 키는 영문 `snake_case`로 고정하며 번역하거나 임의로 바꾸지 않는다.
- 상태, 판정, 대체 표식(sentinel)은 아래에 정의한 영문 열거값(enum)을 사용한다. 자유 서술만 한국어로 작성한다.
- 필수 필드는 값이 없더라도 삭제하거나 비워 두지 않는다. 적용할 수 있지만 값이 없으면 `NONE`, 조건 자체가 적용되지 않으면 `NOT_APPLICABLE`을 기록한다.
- 하나의 trace 안에서 단일 값(scalar) 필드 키를 중복하지 않는다. 반복 가능한 항목은 템플릿의 표에 행으로 추가하며, 표의 열 식별자는 해당 표의 구조 식별자 안에서 해석한다.
- 최소·확장 템플릿의 공통 필드는 이름, 순서와 의미를 동일하게 유지한다.
- `schema_version`은 정수로 기록한다. 필드 삭제·이름 변경·의미 변경이나 enum 제거처럼 기존 판독을 깨는 변경에서만 버전을 올린다.
- 확장 적용 조건 필드(trigger)가 `false`이면 해당 섹션의 단일 값은 `NOT_APPLICABLE`, 표는 모든 열이 `NOT_APPLICABLE`인 한 행으로 기록한다. 적용 조건이 `true`이면 필수 근거를 미치환 placeholder 없이 작성한다.

현재 공통 열거값은 다음과 같다.

| 필드·용도 | 허용 값 |
|---|---|
| `trace_level` | `minimum`, `extended` |
| `task_type` | `bug_fix`, `feature`, `behavior_change`, `repeated_work`, `code_review`, `other` |
| `final_result`, evaluator 판정 | `PASS`, `FAIL`, `BLOCKED` |
| 승인 결정 | `APPROVED`, `DENIED`, `PENDING` |
| 역할 상태 | `COMPLETED`, `NEEDS_LEAD_DECISION`, `NEEDS_USER_APPROVAL`, `BLOCKED` |
| 비교 품질 | `IMPROVED`, `UNCHANGED`, `DEGRADED` |
| 결과 채택 | `ADOPTED`, `REJECTED`, `PARTIAL` |
| 적용 여부 | `true`, `false` |
| 값 없음·조건 미적용 | `NONE`, `NOT_APPLICABLE` |
| 사용자 보고 일치 | `CONSISTENT`, `INCONSISTENT`, `PENDING` |

현재 [`scripts/doctor.sh`](../../scripts/doctor.sh)의 Harness-Diagnostics는 최소한 다음 항목을 검사한다.

- 지원하는 `schema_version`과 필수 키 존재 여부
- 현재 baseline 버전과 변경 이력의 단일 활성 행 및 적용일 정합성
- `trace_id`·파일 이름 일치, 식별자 중복과 시간 형식
- 허용되지 않은 열거값, 미치환 placeholder, 빈 필수 값과 중복 필드
- 성공 조건 미완료, evaluator 결과와 `final_result`의 모순
- 확장 적용 조건과 조건별 섹션 작성 여부
- 재작업 횟수, 역할 독립성, 승인 결정과 실제 수행 결과의 정합성
- 절대 사용자 경로, 알려진 비밀 패턴과 마스킹되지 않은 민감정보

Diagnostics는 자유 서술의 문장이나 번역된 표시 문구를 판정 기준으로 사용하지 않고, 고정 필드 키·enum과 제목·표 안의 백틱 구조 식별자를 기준으로 검사한다.

진단 규칙을 변경하면 [`scripts/test-doctor-harness.sh`](../../scripts/test-doctor-harness.sh)의 정상·오류 fixture도 함께 갱신한다. template과 진단 테스트는 Git으로 관리하고, `runs/`는 존재할 때만 검사한다.

## 기록 절차

1. 작업을 시작할 때 작업 수준, 적용 task, 성공 조건과 trace 수준을 정한다.
2. 실행 중에는 재시도, 역할 상태 변경, 승인 결정과 외부 행동처럼 결과 판정에 영향을 주는 사건만 기록한다.
3. 통합된 상태에서 evaluator를 실행하고 명령, `PASS`·`FAIL`·`BLOCKED` 판정과 요약 근거를 남긴다.
4. 검증하지 못한 항목과 남은 위험을 최종 사용자 보고와 일치시킨다.
5. 완료 시 필수 항목, 민감정보, 파일 식별자와 결과 판정을 검토한다.

Trace는 작업 종료 후 기억에 의존해 새로 구성하지 않는다. 다만 긴 도구 출력이나 진행 과정을 실시간으로 전부 복사하지 않고, 판정에 필요한 사건이 발생할 때 구조화된 요약을 갱신한다.

## 식별자와 파일 이름

- `trace_id`: `tr-YYYYMMDD-<slug>-<sequence>` 형식을 사용한다. 예: `tr-20260902-trace-contract-01`.
- `run_id`: 반복 평가의 개별 실행에만 `run-<sequence>` 형식을 사용한다.
- 작업별 로컬 파일 이름은 `<trace_id>.md`로 한다.
- `trace_id`는 한 저장소 안에서 중복하지 않는다. 동일 작업의 재시도는 새 trace가 아니라 시도·재작업 항목에 기록하고, 독립적으로 비교할 재실행만 새 trace와 `run_id`를 부여한다.
- 시간은 한국시간을 바로 확인할 수 있도록 ISO 8601 형식의 `+09:00` 오프셋으로 기록한다.

## 상태와 판정

| 값 | 의미 |
|---|---|
| `PASS` | 필수 성공 조건과 evaluator를 충족함 |
| `FAIL` | 실행 가능한 evaluator가 실패했거나 필수 성공 조건을 충족하지 못함 |
| `BLOCKED` | 필요한 승인, 입력 또는 실행 환경이 없어 현재 조건에서 판정할 수 없음 |

개별 역할의 `COMPLETED`, `NEEDS_LEAD_DECISION`, `NEEDS_USER_APPROVAL`, `BLOCKED` 상태는 [역할 계약](../roles/README.md#일시-중단과-재개)에 따라 기록한다. 역할의 `COMPLETED`를 전체 trace의 `PASS`로 간주하지 않는다. Lead가 통합 결과와 evaluator를 근거로 최종 판정을 기록한다.

## 보관과 Git 정책

- 템플릿과 이 문서는 Git으로 관리한다.
- 작업별 원본 trace는 `.harness/traces/runs/`에 저장하며 기본적으로 Git에 포함하지 않는다.
- 원본 trace의 기본 보관 기간은 30일이다. 미완료 작업, 장애 조사, report 작성 또는 candidate 평가·승격의 근거로 사용 중인 trace는 해당 report가 확정되고 candidate가 `PROMOTED`, `REJECTED` 또는 `DEFERRED`가 될 때까지 보관한다.
- 보관 기간이 지난 로컬 trace는 사용자가 정리한다. 자동 삭제나 Git 이력 변경은 이 계약의 범위에 포함하지 않는다.
- Harness-Diagnostics는 원본 trace가 로컬에 남아 있으면 report·candidate의 참조와 내용을 엄격히 대조한다. 정상 보관 정책에 따라 정리된 원본의 부재만으로 durable report나 terminal candidate를 무효화하지 않으며, 이때는 report source inventory와 candidate의 구조화된 비교·승격 메타데이터를 기준 증거로 사용한다.
- 공유가 필요한 trace는 먼저 최소 정보 원칙과 마스킹 규칙으로 검토한 뒤, 사용자의 명시적 요청에 따라 별도 산출물이나 이후 `reports/`의 집계 근거로 작성한다.
- 로컬 trace를 커밋, 외부 문서 또는 메시지로 게시하는 행동은 [승인 정책](../policies/approval-policy.md)의 대상·외부 행동 경계를 따른다.

`runs/`가 없으면 작업 시작 시 생성한다. 이 디렉터리는 [저장소 `.gitignore`](../../.gitignore)에 의해 무시된다.

## 민감정보와 마스킹

다음 원문은 trace에 기록하지 않는다.

- API key, access token, cookie, password, private key와 전체 연결 문자열
- 개인정보, 운영 데이터 row, 고객 입력과 비공개 문서 원문
- 전체 사용자 프롬프트, 전체 대화, 긴 명령 출력, 환경 변수 전체 목록
- 공개할 필요가 없는 절대 사용자 경로, 내부 호스트명과 계정 식별자

근거가 필요하면 다음처럼 최소 식별자와 상태만 남긴다.

| 원문 유형 | 기록 방식 |
|---|---|
| 비밀값 | `[REDACTED:SECRET]`과 사용 여부·성공 여부만 기록 |
| 개인정보·운영 데이터 | `[REDACTED:SENSITIVE_DATA]`와 비식별 건수·스키마만 기록 |
| 사용자 경로 | 저장소 상대 경로로 변환 |
| URL·호스트 | 공개 가능한 서비스명 또는 `[REDACTED:ENDPOINT]` 사용 |
| 긴 출력 | 실행 명령, 종료 코드, 핵심 오류와 결과 요약만 기록 |
| 사용자 요청 | 성공 조건 판단에 필요한 비민감 요약만 기록 |

마스킹 전 원문을 먼저 trace에 저장하지 않는다. 비밀값이 실수로 기록되면 공유·커밋을 중단하고 해당 값을 노출된 것으로 취급해 기존 보안 절차에 따라 대응한다. 단순 문자열 치환만으로 안전하다고 간주하지 않고 문맥상 재식별 가능성도 검토한다.

## 품질 기준

완료된 trace는 다음 조건을 모두 만족해야 한다.

- 적용 task와 성공 조건이 현재 사용자 요청을 식별할 수 있을 만큼 구체적이다.
- 변경 파일과 evaluator 명령은 저장소 상대 경로와 재실행 가능한 수준으로 기록되어 있다.
- 각 evaluator의 판정과 전체 최종 판정이 모순되지 않는다.
- 재시도·재작업 횟수와 원인이 실제 실행과 일치한다.
- 미검증 항목과 남은 위험이 최종 보고에서 누락되지 않는다.
- 강화 조건에 해당하는 확장 섹션이 작성되어 있다.
- 비밀값, 개인정보, 운영 데이터 원문과 불필요한 긴 출력이 없다.
- 필수 키, 열거값, 대체 표식과 확장 적용 조건이 호환 계약을 따른다.

## 디렉터리 구성

trace template을 추가하거나 이름을 바꾸면 적용 수준 표와 아래 디렉터리 구성을 함께 갱신한다. `doctor.sh`는 template 링크·필수 필드·섹션·표 구조와 로컬 run의 계약을 검사한다.

```text
.harness/traces/
├── README.md
├── templates/
│   ├── minimum-trace.md
│   └── extended-trace.md
└── runs/                    # 로컬 실행 기록, Git 제외
```
