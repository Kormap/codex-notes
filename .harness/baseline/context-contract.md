# Context Contract

## 책임 경계

- `AGENTS.md`: 모든 작업의 우선순위, 공통 행동, 검증, 안전과 응답 방식
- Domain skill: description이 일치하는 작업의 구현·리뷰 판단과 필요한 reference
- `dev-harness`: Harness 적용 수준과 읽을 문서 선택
- Harness baseline: 모든 Harness 작업의 공통 실행·검증 계약
- Task/evaluator: 선택된 작업의 범위·성공 조건과 판정 방법
- Policy/role/trace: 해당 조건의 승인·협업 통제와 기록 형식

## 적용 순서

1. 시스템과 플랫폼 안전 지침
2. 사용자의 현재 명시적 요청과 승인
3. 대상 프로젝트의 더 구체적인 지침과 확립된 관례
4. 전역 `AGENTS.md`
5. 선택된 domain skill과 필요한 reference
6. `dev-harness`, 현재 baseline과 적용되는 승인·병렬 작업 policy
7. 선택된 task, evaluator와 trace 실행 계약·template
8. 실제 배정된 role과 확장 trace 계약

아래 단계는 위 단계의 의미를 구체화할 수 있지만 충돌하거나 범위·권한을 확대할 수 없다. 실질적인 충돌은 상위 지침을 따르고 사용자에게 알린다.

`candidates/`는 평가 대상이며 명시적으로 승격되기 전에는 현재 baseline처럼 적용하지 않는다. Harness 작업을 시작하기 전에는 목표, 범위, 중요한 불확실성, 성공 조건, 검증 방법, trace 수준과 사용자 보고 근거를 확인한다.

이 문서의 우선순위나 실행 의미를 바꾸기 전에는 [유지보수 계약](../maintenance.md)을 적용한다.
