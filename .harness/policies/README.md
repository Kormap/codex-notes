# Harness Policies

이 디렉터리는 Harness 작업의 승인 경계와 멀티·서브에이전트 협업 통제를 정의한다. 정책은 [`AGENTS.md`](../../AGENTS.md)와 [Harness baseline](../baseline/README.md)을 대체하지 않으며, 승인이나 협업 통제가 필요한 행동을 구체화한다.

## 정책 선택

| 조건 | 적용 정책 |
|---|---|
| 승인 경계를 넘는 행동 | [approval-policy.md](approval-policy.md) |
| 고위험 단일 에이전트 작업 | [approval-policy.md](approval-policy.md) |
| 멀티·서브에이전트 작업 | [approval-policy.md](approval-policy.md) + [parallel-work-policy.md](parallel-work-policy.md) |

작업 수준과 관계없이 승인 대상 행동을 수행하려면 승인 정책을 적용한다. 멀티·서브에이전트 작업은 플랫폼과 상위 지침이 허용하는 범위에서만 수행하며, 병렬 작업 정책을 추가 적용한다.

## 공통 원칙

- 상위 지침과 사용자의 현재 요청을 약화하거나 확장하지 않는다.
- 안전한 로컬 작업은 승인 요청을 반복하지 않고 요청 범위 안에서 수행한다.
- 외부 변경, 파괴적 행동, 비용 발생, 중요한 범위 확장은 실행 전에 승인 경계를 확인한다.
- 승인은 명시된 행동, 대상, 환경, 현재 작업에만 유효하며 다른 작업이나 대상으로 자동 승계하지 않는다.
- 승인되지 않은 행동을 우회하거나 더 작은 행동으로 나누어 실행하지 않는다.
- 정책 적용 결과와 중요한 승인 결정은 해당 trace에 남긴다.

## 책임 경계

- [approval-policy.md](approval-policy.md)는 어떤 행동을 누가 언제 승인해야 하는지 정의한다.
- [parallel-work-policy.md](parallel-work-policy.md)는 Lead의 통합 책임, writer 소유권, 병렬화와 worktree 선택 기준을 정의한다.
- [roles/README.md](../roles/README.md)는 각 실행 역할의 세부 입력·산출물 계약을 정의하며, 이 디렉터리의 승인과 소유권 경계를 변경하지 않는다.

정책 문서를 추가하거나 이름을 바꾸면 이 README의 정책 선택·책임 경계 링크도 함께 갱신한다. [`scripts/doctor.sh`](../../scripts/doctor.sh)는 실제 정책 문서와 색인 링크의 일치 여부를 검사한다.
