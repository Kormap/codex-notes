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
