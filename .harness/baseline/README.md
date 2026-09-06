# Harness Baseline

이 문서는 모든 Harness 작업에 공통 적용하는 실행·검증 계약의 canonical source다. 적용 여부와 추가 문서는 [`dev-harness`](../../skills/dev-harness/SKILL.md)가 선택한다.

## 공통 계약

1. 요청을 목표, 허용 범위와 검증 가능한 성공 조건으로 해석한다.
2. 데이터, 운영 동작, 외부 비용, 보안 또는 중요한 설계를 바꾸는 불확실성은 실행 전에 확인한다.
3. 승인된 범위 안에서 가장 작은 완전한 변경만 수행한다.
4. 선택한 task와 evaluator를 현재 요청에 맞게 구체화하되 기준을 약화하지 않는다.
5. 가장 좁고 충분한 검증으로 성공 조건을 `PASS`, `FAIL` 또는 `BLOCKED`로 판정한다.
6. 실제 변경, 검증, 미검증 항목과 남은 위험을 trace와 사용자 보고에 일치시킨다.

읽기 전용 작업은 변경·테스트 단계를 만들지 않고 근거와 판단 한계를 보고한다. 사용자가 파일 기록을 요청하거나 승인하지 않으면 trace를 만들지 않는다.

Baseline 의미·우선순위·실행 계약을 바꾸기 전에는 [유지보수 계약](../maintenance.md)을 읽는다. 개선 동기와 무관하게 candidate 평가와 승인 없이 현재 기준으로 승격하지 않는다.

## 문서 구성

- [context-contract.md](context-contract.md): 지침 책임과 적용 순서
- [terminology.md](terminology.md): 응답 프로필, 실행 역할, Skill과 Trace 정의
- [version.md](version.md): 현재 baseline 버전, 변경 수준·근거와 적용일·이력 규칙

문서를 추가하거나 이름을 바꾸면 이 색인을 갱신한다. 검사 대상이나 구조 계약이 달라질 때만 [`scripts/doctor.sh`](../../scripts/doctor.sh)와 회귀 fixture도 갱신한다.
