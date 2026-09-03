# Harness Terminology

Harness 문서와 관련 응답에서는 다음 용어를 일관되게 사용한다.

## 응답 프로필 (Response profile)

작업을 어떤 분석 관점과 응답 깊이로 다룰지 나타내는 분류다. 현재 예시는 `DEFAULT`, `BACKEND`, `FRONTEND`, `DB`, `INFRA`, `BATCH`, `GENERATOR`, `LEGACY`다.

- 답변 첫 줄의 `[BACKEND · STANDARD]`에서 `BACKEND`는 응답 프로필이다.
- 여러 관점이 필요하면 `[DB + BACKEND · FULL]`처럼 조합할 수 있다.
- 응답 프로필은 별도 프로세스나 서브에이전트를 뜻하지 않는다.

## 실행 역할 (Execution role)

작업 실행 과정에서 누가 어떤 책임과 권한을 갖는지 나타낸다. 초기 역할 명칭은 `Lead`, `Researcher`, `Implementer`, `Reviewer`, `Verifier`로 고정한다.

- `Lead`: 범위 해석, 작업 분해, 승인 판단, 결과 통합, 최종 보고
- `Researcher`: 승인된 범위의 읽기 전용 조사와 근거 수집
- `Implementer`: 승인된 파일 범위의 변경과 자체 검증
- `Reviewer`: 변경의 결함, 회귀, 누락, 운영 위험 검토
- `Verifier`: 정의된 검증 실행과 PASS/FAIL 근거 제시

역할별 입력, 권한, 금지 행동, 완료 조건과 반환 계약은 [roles/README.md](../roles/README.md)에서 정의한다. 역할 배정은 승인 정책과 파일 소유권을 포함한 상위 경계를 확장하지 않는다.

## Skill

특정 도메인이나 작업 유형에 선택적으로 적용하는 재사용 가능한 전문 지침이다. 예를 들어 `query-plan-review`는 SQL 실행계획 분석 지침이고, `test-generator`는 테스트 생성·보강 지침이다.

- Skill은 실행 역할이 아니며, 동일한 역할이 작업에 따라 서로 다른 Skill을 사용할 수 있다.
- Skill은 응답 프로필이 아니며, Skill 선택이 별도 에이전트 생성을 의미하지 않는다.
- Skill 지침은 상위 지침과 현재 작업 범위 안에서만 적용한다.

## Trace

Harness 작업의 입력, 실행, 검증, 결과를 Meta-Harness가 비교할 수 있게 구조화한 증거다.

- **최소 trace**: 모든 Harness 작업이 남기는 공통 평가 근거다. task, 성공 조건, evaluator 결과, 변경 범위, 재작업, 검증 한계, 적용 Skill을 포함한다.
- **확장 trace**: 강화 Harness 작업이 최소 trace에 위험·승인, 반복 실행 비교 또는 멀티에이전트 협업 근거를 추가한 기록이다.
- trace는 코드 전체나 긴 명령 출력을 보존하는 작업 로그가 아니다. 재현과 판정에 필요한 식별자와 결과 요약을 기록한다.

## Meta-Harness

여러 trace를 report로 집계해 반복 실패, 검증 누락, 재작업 원인을 찾고 Harness 개선안을 평가하는 체계다. 개선안은 candidate로 분리해 대표 task와 evaluator로 재평가하며, 통과한 변경만 baseline에 승격한다.

## 혼용 금지

- `BACKEND`, `DB` 등을 실행 역할이나 에이전트 이름으로 부르지 않는다.
- `Reviewer`, `Verifier` 등을 응답 프로필로 사용하지 않는다.
- Skill 이름으로 작업 소유자나 최종 의사결정자를 표현하지 않는다.
- trace를 전체 작업 로그나 최종 report와 같은 의미로 사용하지 않는다.
- 일반적인 자동화 주체를 뜻하는 경우를 제외하고, 분석 관점을 통칭하는 용어로 `Agent`를 사용하지 않는다.
