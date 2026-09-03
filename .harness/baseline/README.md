# Harness Baseline

`AGENTS.md`는 모든 Codex 작업에 적용한다. Harness baseline은 `AGENTS.md`만으로 재현성, 검증 증거, 또는 협업 통제가 충분하지 않은 작업에 추가 적용한다. baseline은 Harness 대상 작업의 최소 계약이다.

baseline과 함께 `task`, `evaluator`, 최소 `trace`를 적용한다. 고위험·반복 품질 평가·멀티에이전트 작업은 trace를 확장하고, 위험 통제나 협업 통제에 필요한 `roles`와 `policies`를 조건에 따라 추가한다. 세부 선택 기준은 [상위 Harness 문서](../README.md#적용-범위)를 따른다.

## 공통 계약

Harness 대상 작업은 다음 흐름을 따른다.

1. 요청을 목표, 범위, 성공 조건으로 해석한다.
2. 결과에 실질적인 영향을 주는 불확실성은 실행 전에 사용자에게 확인한다.
3. 승인된 범위 안에서 필요한 최소 변경만 수행한다.
4. 작업 유형과 위험에 맞는 가장 좁고 충분한 검증을 수행한다.
5. 최소 trace에 작업과 검증 결과를 구조화해 남긴다.
6. 수행 내용, 변경 파일, 검증 결과, 남은 위험을 근거와 함께 보고한다.
7. 반복 실패나 검증 누락에서 나온 개선안은 바로 baseline에 넣지 않고 candidate로 분리해 평가한다.

읽기 전용 답변처럼 파일 변경이 없는 작업은 변경·테스트 단계를 억지로 만들지 않는다. 대신 사용한 근거와 판단 한계를 명확히 한다.

## 최소 trace 계약

모든 Harness 작업의 trace는 다음 항목을 포함한다.

- 작업 유형과 적용 task
- 성공 조건
- 실행한 evaluator와 PASS/FAIL 결과
- 변경 범위
- 재시도·재작업 횟수
- 검증하지 못한 항목과 남은 위험
- 적용한 Skill

최소 trace는 Meta-Harness가 반복 실패, 검증 누락, 재작업 원인을 비교할 수 있는 정도로 남긴다. 강화 Harness의 조건별 확장 항목은 [상위 Harness 문서](../README.md#trace-수준)를 따른다.

## 문서 구성

- [context-contract.md](context-contract.md): `AGENTS.md`, 프로젝트 지침, Harness 문서의 책임과 적용 순서
- [terminology.md](terminology.md): 응답 프로필, 실행 역할, Skill의 고정 정의
- [version.md](version.md): 현재 baseline 버전과 변경 규칙

## 변경 원칙

초기 baseline은 저장소 소유자의 명시적 승인으로 설정한다. 이후 변경은 trace나 report에서 확인된 문제와 검증 결과를 근거로 candidate를 평가한 뒤 반영한다. 상위 지침을 약화하거나 특정 작업의 일회성 예외를 공통 baseline으로 승격하지 않는다.

baseline 문서를 추가하거나 이름을 바꾸면 이 README의 문서 구성 링크도 함께 갱신한다. [`scripts/doctor.sh`](../../scripts/doctor.sh)는 실제 문서와 색인 링크의 일치 여부를 검사한다.
