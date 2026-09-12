---
name: dev-harness
description: 비단순 구현·리팩터링·설정·버그 수정·검증 중심 리뷰를 task와 evaluator로 검증한다. 고위험·반복 평가·멀티에이전트는 변경 크기와 무관하게 적용한다.
---

# Development Harness

사용자 범위 안에서 성공 조건과 검증 근거를 유지한다. 단순 문법·개념 질문과 낮은 위험의 한 줄 수정·짧은 읽기 전용 확인은 제외한다. 고위험·반복 품질 평가·멀티에이전트 조건은 이 예외보다 우선한다.

## 중앙 Harness 찾기

이 skill 위치의 [scripts/resolve-root.sh](scripts/resolve-root.sh)를 `sh`로 실행한다. 반환된 절대 경로를 중앙 저장소 root로 사용한다. 아래 `../../.harness/` 링크는 원본 저장소 기준이며, 복사 설치에서는 resolver가 반환한 root 아래의 `.harness/`로 읽는다. 현재 작업 프로젝트나 `~/.agents/.harness`를 중앙 저장소로 추정하지 않는다. 해결 실패 시 먼저 setup 상태를 확인하고 필요한 계약 없이 실행을 계속하지 않는다.

## Task와 검증 선택

먼저 [baseline](../../.harness/baseline/README.md)을 읽고 주 task/evaluator 한 쌍을 선택한다. 복합 작업에서는 추가 변경 영역의 evaluator를 함께 읽어 모든 필수 검사를 판정한다. 주 task 선택이 추가 검증을 제외하는 이유가 되어서는 안 된다.

| 작업 | Task | Evaluator |
|---|---|---|
| Backend 결함 | [backend-bugfix](../../.harness/tasks/backend-bugfix.md) | [backend-bugfix](../../.harness/evaluators/backend-bugfix.md) |
| Backend API | [backend-api-feature](../../.harness/tasks/backend-api-feature.md) | [backend-api-feature](../../.harness/evaluators/backend-api-feature.md) |
| SQL·인덱스 성능 | [query-performance](../../.harness/tasks/query-performance.md) | [query-performance](../../.harness/evaluators/query-performance.md) |
| Frontend 동작 | [frontend-change](../../.harness/tasks/frontend-change.md) | [frontend-change](../../.harness/evaluators/frontend-change.md) |
| Harness 계약 결함 | [harness-contract](../../.harness/tasks/harness-contract.md) | [harness-contract](../../.harness/evaluators/harness-contract.md) |

정확히 맞는 task가 없으면 영구 task를 만들지 말고 현재 요청 식별자를 `task_reference`로 사용한다. [evaluator 공통 계약](../../.harness/evaluators/README.md)을 읽고 현재 요청의 성공 조건별로 필수 여부, 검증 방법과 PASS/FAIL/BLOCKED 기준을 trace 또는 읽기 전용 응답에 정의한다. 반복될 대표 작업일 때만 task/evaluator 추가를 제안한다.

선택한 task의 입력·범위·금지 행동과 성공 조건을 현재 요청에 맞게 구체화하되 기준을 약화하거나 실패한 조건을 삭제하지 않는다. `NOT_APPLICABLE`은 evaluator가 허용하는 조건에만 사유와 함께 사용한다. 필요한 입력·환경이 없으면 추정으로 통과시키지 않는다. 실제 검증 명령은 대상 프로젝트의 지침·wrapper·기존 script에서 선택한다.

## 실행 모드 라우팅

작업을 시작하기 전에 Lead가 현재 요청 전체를 대상으로 다음 gate를 순서대로 판정하고, 각 `YES` 또는 `NO`의 구체적 근거를 실행 결과에 남긴다.

| Gate | `YES` 조건 | `NO` 조건 |
|---|---|---|
| `G1` 독립 작업 단위 | 요청에 둘 이상의 식별 가능한 작업 단위가 있고 각 단위가 상대 작업의 중간 결과 없이 자체 산출물을 만들 수 있음 | 단일 작업 단위이거나 앞 단계 결과가 다음 단계의 필수 입력 |
| `G2` 의존성 분리 | 읽기 범위 또는 writer 경로가 분리되고 공유 상태 변경이 없음 | 같은 파일·공용 상태·미확정 설계를 함께 다룸 |
| `G3` 채택·통합 기준 | 단위별 완료 조건과 반환 형식, 결과 채택 기준과 Lead의 최종 검증 지점이 요청·task·evaluator에서 확인됨 | 완료·채택 기준이나 최종 검증 지점을 실행 전에 정할 수 없음 |
| `G4` 실행 이득 | 독립 단위의 동시 실행으로 critical path를 줄이거나 서로 다른 필수 관점의 독립 검토로 발견 품질을 높임 | 순차 의존 또는 공유 writer 때문에 조율·재검증 비용이 이득보다 큼 |

Gate는 서로의 질문을 대신하지 않는다. 둘 이상의 작업 단위가 같은 최종 계약에 연결돼도 `G1`은 각 단위가 별도 산출물을 만들 수 있으면 `YES`이고, 공유 상태·writer 결합은 `G2`에서 판정한다. `G3`은 병렬화 여부가 아니라 완료·채택·최종 검증의 명확성을 묻기 때문에 순차 작업도 기준이 고정돼 있으면 `YES`다. `G4`는 fixture의 파일 크기만으로 `NO`로 낮추지 않고 요청된 작업 단위와 필수 관점의 실제 범위를 기준으로 판정한다.

대표 경계는 다음과 같다.

- 서로 독립된 두 자료의 조사·종합은 독립 분석과 통합 기준이 있으므로 네 gate가 모두 `YES`다.
- 하나의 결함을 재현하고 원인 규명·수정·검증하는 흐름은 순차 의존이므로 `G1/G2/G4=NO`지만 합격 기준과 최종 검증이 명확하면 `G3=YES`다.
- 하나의 변경을 보안·성능·회귀처럼 서로 다른 필수 관점으로 검토하는 작업은 독립 관점의 발견 품질 이득이 있으므로 네 gate가 모두 `YES`다.
- 공용 설정과 연결된 migration처럼 별도 산출물은 있지만 같은 상태 계약과 단일 writer가 필요한 작업은 `G1/G3=YES`, `G2/G4=NO`다.
- 경로가 겹치지 않는 두 모듈의 독립 결함 수정과 모듈별 검증은 최종 통합 검증 지점이 고정돼 있으면 네 gate가 모두 `YES`다.

네 gate가 모두 `YES`일 때만 `routing_decision=MULTI`로 정한다. 하나라도 `NO`이거나 근거가 부족하면 `routing_decision=MAIN`이며 Lead가 직접 순차 실행한다. 위험도가 높다는 사실만으로 `MULTI`를 선택하지 않는다.

`routing_decision`을 정한 뒤 플랫폼·상위 지침의 delegation 허용 여부와 collaboration 도구·동시 슬롯 가용성을 확인한다.

`delegation_allowed`는 정책상 허용만이 아니라 이번 실행에서 필요한 delegation 도구와 슬롯까지 실제 사용 가능한지를 합친 최종 불리언이다. 상위 지침 금지, 도구 없음·호출 실패 또는 슬롯 부족으로 fallback하면 `false`다. 실행 전에 가능하다고 판단했어도 delegation 호출이 도구 오류로 실패하면 `false`로 갱신한 뒤 확인된 fallback 사유를 기록한다.

- `MAIN`은 `actual_execution=MAIN`, `fallback_reason=NONE`으로 실행하며 delegation이나 agent assignment를 만들지 않는다.
- `MULTI`이고 delegation이 허용되면 둘 이상의 독립 작업을 실제로 위임해 `actual_execution=MULTI`로 실행한다. 실행 전에 각 작업의 ID, 역할, 읽기·쓰기 범위, 금지 행동, 반환 계약과 evaluator를 배정한다. 한 파일에는 한 writer만 두고 공용 설정·migration·최종 통합은 Lead가 소유한다.
- `MULTI`이지만 상위 지침이 delegation을 금지하거나 도구·슬롯이 없으면 `actual_execution=MAIN_FALLBACK`으로 Lead가 직접 수행한다. 이때 assignment와 delegation을 만들지 않고 `fallback_reason`을 `DELEGATION_FORBIDDEN_BY_HIGHER_INSTRUCTION`, `DELEGATION_TOOL_UNAVAILABLE`, `CONCURRENCY_CAPACITY_UNAVAILABLE` 중 확인된 하나로 기록한다. 병렬 효과와 역할 독립성은 `unverified`로 남긴다.
- delegation이 허용된 환경에서 편의상 위임을 생략하거나 역할명을 서술하는 것만으로 `MULTI` 또는 fallback을 주장하지 않는다.

Lead는 각 역할 반환을 근거와 함께 `ADOPTED`, `REJECTED`, `PARTIAL` 중 하나로 판정하고, 채택 결과를 통합한 최종 상태에서 선택한 evaluator를 직접 다시 실행한다. 역할별 완료나 검사 통과를 통합 성공으로 대신하지 않는다. 실제 변경 파일은 배정한 상대 경로와 대조하고 경로 중첩·범위 밖 변경이 있으면 통합하지 않는다.

구조화 결과의 `integration_command`에는 선택한 통합 evaluator 명령 하나만 정확히 기록한다. `git diff --check` 같은 보조 검사를 추가로 실행해도 이 필드에 `&&`로 합치지 않고 별도 검증 근거에 남긴다.

## 조건부 Skill 라우팅

Task와 evaluator를 선택한 뒤 현재 변경·검증 범위에 실제로 해당하는 최소한의 Skill만 다음 순서로 함께 적용한다. 키워드가 언급됐다는 이유만으로 선택하지 않으며, 선택한 Skill의 `SKILL.md`와 현재 작업에 필요한 reference만 읽는다. 각 Skill은 해당 도메인의 실행 기준을 제공하고, task 범위·성공 조건과 최종 `PASS`, `FAIL`, `BLOCKED` 판정은 Harness가 유지한다.

### 1. 작업 유형

- GitHub PR, branch diff, staged diff 또는 변경 파일 리뷰: `pr-review`

### 2. 주 도메인

- Java/Spring, infrastructure, batch 또는 legacy 구현·설계·리뷰: `engineering-standards`
- JSP/JSTL, Vue, React, CSS와 브라우저 UI: `frontend-ui-review`
- JPA, JPQL, QueryDSL, fetch 전략 또는 OSIV: `jpa-performance-review`
- MyBatis XML, mapper, DTO, resultMap 또는 동적 SQL: `mybatis-xml-review`
- SQL, EXPLAIN, 실행계획, index, join, paging 또는 count 비용: `query-plan-review`
- schema mapping, ETL/SQL, backfill, CDC, reconciliation, cutover 또는 recovery: `data-migration`. 매핑·재실행·대사가 필요 없는 단순 로컬 복사는 제외한다.

복합 작업에서는 변경 영역마다 필요한 주 도메인 Skill을 조합한다. 넓은 `engineering-standards`와 더 구체적인 Skill이 함께 적용되면 공통 운영 기준은 전자를, 세부 도메인 판단은 후자를 정본으로 사용한다.

### 3. 교차 관심사

- Spring transaction, rollback, lock, connection 점유, 외부 호출 또는 데이터 정합성: `spring-transaction-audit`
- log, traceId·MDC, metric, alert 또는 장애 추적성: `logging-observability`
- Java/Spring 배포, DB migration 순서, config·flag, graceful shutdown, rollback, health check 또는 rollout: `deploy-checklist`

교차 관심사가 단지 주변 코드에 존재하는 경우에는 추가하지 않고, 현재 변경이나 성공 조건에 영향을 줄 때만 적용한다.

### 4. 테스트

- JUnit, Mockito 또는 Spring 통합 테스트를 생성·수정해 회귀, 경계값, 동시성이나 실패 경로를 보강하는 작업: `test-generator`

기존 테스트를 evaluator 명령으로 실행하기만 하는 경우에는 `test-generator`를 적용하지 않는다. Skill을 함께 적용해도 테스트를 약화하거나 변경 범위 밖의 테스트를 추가하지 않는다.

위임 대상 Skill을 사용할 수 없거나 해당 계약을 읽을 수 없으면 그 내용을 추정해 대체하지 않는다. 가능한 Harness 범위만 수행하고 필수 성공 조건을 신뢰성 있게 판정할 수 없으면 `BLOCKED`와 미검증 위험을 보고한다. 상위 지침과 사용자 범위가 항상 우선하며 Skill 조합은 실행 권한을 확대하지 않는다.

## 기록과 판정

일반 작업은 최소 trace, 고위험·반복 품질 평가·멀티에이전트는 확장 trace를 사용한다. 선택한 task가 더 높은 수준을 요구하면 이를 따른다. 읽기 전용 작업은 사용자의 기록 요청·승인이 없으면 trace를 생성하지 않고 응답에 근거와 한계를 남긴다.

Trace를 작성할 때는 [실행 계약](../../.harness/traces/runtime.md)과 해당 [최소](../../.harness/traces/templates/minimum-trace.md) 또는 [확장 template](../../.harness/traces/templates/extended-trace.md)을 먼저 읽는다. 선택된 evaluator의 모든 필수 검사를 판정하고 실제 결과·미검증 항목·남은 위험을 사용자 보고와 일치시킨다.

## 조건부 문서

- 고위험 또는 외부 상태 변경: [approval policy](../../.harness/policies/approval-policy.md)
- 멀티·서브에이전트: [roles](../../.harness/roles/README.md), [parallel policy](../../.harness/policies/parallel-work-policy.md)와 실제 배정한 역할 문서
- Harness·router·Diagnostics 변경: [유지보수 계약](../../.harness/maintenance.md). Baseline 의미·우선순위·실행 계약 변경은 [version](../../.harness/baseline/version.md)과 [candidate 계약](../../.harness/candidates/README.md)도 반드시 읽는다.
- Report 집계: [reports](../../.harness/reports/README.md)
- Candidate 생성·평가·승격: [candidates](../../.harness/candidates/README.md)와 해당 source report

현재 작업에 해당하는 문서만 읽는다. Skill과 Harness는 상위 지침이나 사용자 승인 범위를 확대하지 않는다.
