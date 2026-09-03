# Codex Harness

이 디렉터리는 Codex 작업을 일관되게 실행하고, 결과를 검증하며, 실행 근거를 바탕으로 작업 방식을 개선하기 위한 Harness를 정의한다.

## 적용 범위

`AGENTS.md`는 모든 Codex 작업에 적용한다. Harness baseline은 `AGENTS.md`만으로 재현성, 검증 증거, 또는 협업 통제가 충분하지 않은 작업에 추가 적용한다. 작업의 위험도, 반복 평가 필요성, 에이전트 구성에 따라 추가 Harness 구성요소의 적용 범위를 확장한다.

| 작업 수준 | 대표 작업 | 적용 구성요소 |
|---|---|---|
| 단순 작업 | 한 줄 수정, 단순 설정, 문법 질문, 짧은 읽기 전용 확인 | `AGENTS.md` |
| Harness 작업 | 일반 버그 수정, 새 기능 구현, 기존 기능 변경, 반복 작업, 검증이 중요한 코드 리뷰 | `AGENTS.md` + `baseline` + `task` + `evaluator` + 최소 `trace`: 재현 가능한 성공 조건, 검증 명령, 평가 근거 적용 |
| 강화 Harness 작업 | 고위험 작업, 반복 품질 평가, 멀티·서브에이전트 작업 | Harness 작업 구성 + 확장 `trace` + 조건별 `roles`·`policies`: 위험·비교·협업 통제 근거 적용 |

적용 단계는 다음 원칙으로 선택한다.

- 단순 작업은 `AGENTS.md`의 범위 확인, 최소 변경, 적절한 검증, 결과 보고 원칙으로 충분하면 Harness를 적용하지 않는다.
- 새로운 사용자 동작, API, 화면 또는 비즈니스 규칙을 구현하는 요청은 기본적으로 Harness 작업으로 분류한다.
- 코드 변경 여부만으로 Harness 적용을 결정하지 않는다. 재현 가능한 성공 조건, 명시적 PASS/FAIL 판정, 검증 증거 보존이 필요하면 Harness 작업으로 분류한다.
- 강화 Harness 작업은 일반 Harness 작업의 구성요소와 계약을 포함한다.
- 고위험, 반복 품질 평가, 멀티·서브에이전트 사용 중 하나라도 해당하면 강화 Harness 작업으로 분류한다.
- 모든 Harness 작업은 Meta-Harness 평가에 필요한 최소 trace를 남긴다.
- 고위험 단일 에이전트 작업은 승인·외부 행동·위험 통제 `policies`와 관련 근거를 적용한다.
- 반복 품질 평가 작업은 실행 간 비교가 가능한 확장 trace를 적용한다.
- 멀티·서브에이전트 작업은 `roles`, 위임·병렬·파일 소유권 `policies`, 에이전트별 결과와 통합 근거를 포함한 확장 trace를 적용한다.
- Harness는 필요한 통제가 생기는 지점부터 적용하며, 작업에 필요한 수준보다 무거운 절차를 적용하지 않는다.

## Trace 수준

### 최소 trace

모든 Harness 작업은 다음 평가 근거를 구조화해 남긴다.

- 작업 유형과 적용 task
- 성공 조건
- 실행한 evaluator와 PASS/FAIL 결과
- 변경 범위
- 재시도·재작업 횟수
- 검증하지 못한 항목과 남은 위험
- 적용한 Skill

코드 전체나 긴 명령 출력은 기본 trace에 복사하지 않는다. 판정 재현에 필요한 명령, 결과 요약, 파일·변경 식별자만 기록한다.

### 확장 trace

강화 Harness 작업은 최소 trace에 해당 조건의 근거를 추가한다.

| 조건 | 추가 근거 |
|---|---|
| 고위험 작업 | 위험 항목, 승인 요청과 결정, 외부 행동, 실패·복구 판단 |
| 반복 품질 평가 | 실행 식별자, 비교 대상, 동일 evaluator 결과, 품질 변화와 재작업 원인 |
| 멀티·서브에이전트 | 실행 역할, 담당 범위, 위임 관계, 파일 소유권, 에이전트별 결과, 통합·최종 검증 결과 |

## Meta-Harness 개선 흐름

Meta-Harness는 일반·강화 Harness의 trace를 공통 입력으로 사용한다. Harness-Diagnostics는 작업 성공을 판정하는 evaluator가 아니라, trace가 집계 입력으로 사용되기 전에 스키마, 필수 근거, 판정 정합성과 민감정보 노출을 검사하는 진단 단계다. Diagnostics의 경고나 오류를 evaluator의 `PASS`·`FAIL`로 대체하지 않는다.

현재 Harness-Diagnostics의 실행 진입점은 [`scripts/doctor.sh`](../scripts/doctor.sh)다. 필수 문서·README 색인, task-evaluator 연결, trace template과 로컬 run의 구조·enum·판정 정합성을 검사한다. 진단 규칙의 정상·오류 경로는 [`scripts/test-doctor-harness.sh`](../scripts/test-doctor-harness.sh)로 회귀 검증한다.

```text
task + evaluator
       ↓
  최소/확장 trace
       ↓
scripts/doctor.sh의 Harness-Diagnostics로 구조·보안·정합성 검사
       ↓
여러 trace를 report로 집계
       ↓
반복 실패·검증 누락·재작업 원인 식별
       ↓
candidate 작성 및 대표 task 재평가
       ↓
통과한 개선안만 baseline 승격
```

## AGENTS.md와의 경계

[`AGENTS.md`](../AGENTS.md)는 Codex가 항상 따라야 하는 행동 원칙, 응답 방식, 도메인별 판단 기준을 정의하는 실행 원본이다. Harness는 이를 대체하거나 복제하지 않고, 작업을 재현 가능하게 실행·검증·개선하는 운영 계약을 추가한다.

| 문서 | 책임 |
|---|---|
| `AGENTS.md` | 지침 우선순위, 기본 행동, 응답 방식, 변경·검증 원칙, 도메인별 판단 기준 |
| `.harness/baseline/` | Harness 대상 작업에 공통 적용할 실행·검증·개선 계약 |
| [`.harness/tasks/`](tasks/README.md) | 대표 작업의 입력, 범위, 금지 행동, 성공 조건 |
| [`.harness/evaluators/`](evaluators/README.md) | 작업별 검증 방법과 `PASS`·`FAIL`·`BLOCKED` 판정 기준 |
| `.harness/policies/` | 승인, 병렬 작업, 파일 소유권, 외부 행동 정책 |
| [`.harness/roles/`](roles/README.md) | Lead와 서브에이전트의 입력·권한·반환·완료 계약 |
| [`.harness/traces/`](traces/README.md) | 일반 Harness의 최소 trace와 강화 Harness의 확장 trace, Diagnostics 호환 스키마, 마스킹·보관 계약 |
| [`scripts/doctor.sh`](../scripts/doctor.sh) | Harness 문서·색인·template·run의 구조와 정합성 진단 |
| [`scripts/test-doctor-harness.sh`](../scripts/test-doctor-harness.sh) | Harness-Diagnostics 정상·오류 fixture 회귀 검증 |
| [`.harness/reports/`](reports/README.md) | Diagnostics를 통과한 여러 trace의 품질·운영 집계와 candidate 판단 근거 |
| [`.harness/candidates/`](candidates/README.md) | report 근거로 작성하고 통제된 반복 비교 후 baseline 승격 여부를 판단하는 개선안 |

충돌과 세부 적용 순서는 [baseline/context-contract.md](baseline/context-contract.md)를 따른다.
승인 경계와 멀티·서브에이전트 협업 통제는 [policies/README.md](policies/README.md)를 따르고, 역할별 실행 계약은 [roles/README.md](roles/README.md)를 따른다.
대표 작업과 evaluator의 선택·연결 규칙은 [tasks/README.md](tasks/README.md)와 [evaluators/README.md](evaluators/README.md)를 따른다.

## 고정 용어

- **응답 프로필(Response profile)**: `BACKEND`, `DB`, `FRONTEND`처럼 분석 관점과 응답 깊이를 안내하는 분류다.
- **실행 역할(Execution role)**: `Lead`, `Researcher`, `Implementer`, `Reviewer`, `Verifier`처럼 작업 수행 책임과 권한을 나타낸다.
- **Skill**: 특정 도메인 작업에 선택적으로 적용하는 재사용 가능한 전문 지침이다.
- **Trace**: Harness 작업의 입력, 실행, 검증, 결과를 Meta-Harness가 비교할 수 있게 구조화한 증거다.
- **Meta-Harness**: 여러 trace를 평가해 개선 candidate를 검증하고 baseline 승격 여부를 결정하는 개선 체계다.

응답 프로필은 실행 주체가 아니며, 실행 역할은 전문 지침이 아니다. 상세 정의는 [baseline/terminology.md](baseline/terminology.md)를 따른다.

## Baseline 버전

baseline 버전과 변경 규칙은 [baseline/version.md](baseline/version.md)에서 확인한다.
