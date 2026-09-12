# 실행 모드 라우팅 통제 평가

이 평가 bundle은 [`execution-mode-routing-current-request-v1`](../../../docs/execution-mode-routing-evaluation-plan.md)의 SCN-01부터 SCN-05까지 재현한다. Candidate A를 포함하지 않으며 활성 `skills/dev-harness/SKILL.md` snapshot으로 baseline을 실행한다.

## 구성

- `workspace/`: 결정적 fixture commit의 source
- `prompts/`: 평가 설계와 동일한 고정 요청 본문
- `routing-result.schema.json`: Codex 최종 응답 schema
- `prepare-workspace.sh`: fixture commit과 실행별 Skill 주입
- `preflight.sh`: fixture commit, Skill catalog/hash와 로컬 도구 확인
- `validate-routing-contract.mjs`: 기대 gate·결정, 실행·writer·통합 결과 검증
- `validate-routing-contract.sh`: Node validator 진입점
- `test-validate-routing-contract.sh`: writer scope 포함·중첩과 exact 변경 목록 회귀 fixture
- `fixture-commit.txt`: 결정적으로 생성되는 고정 fixture commit

## 고정 환경

- model: `gpt-5.6-terra`
- reasoning effort: `medium`
- sandbox: `workspace-write`
- approval: `approve-for-me`
- session: `ephemeral`
- retry: 시나리오당 자동 재시도 없음

## 실행

새 임시 경로와 결과 경로를 준비하고 다음 순서로 실행한다.

```text
prepare-workspace.sh <workspace> <baseline-skill>
preflight.sh <workspace> <baseline-skill> <frozen-config>
codex exec --ephemeral --json -C <workspace> ... <prompts/SCN-NN.txt>
<workspace>/evaluation/validate-scenario.sh SCN-NN
validate-routing-contract.sh <result.json> SCN-NN <workspace>
```

Validator 회귀 fixture는 본 평가 전에 다음 명령으로 실행한다.

```text
test-validate-routing-contract.sh
```

`codex exec`에는 사용자 설치본 `dev-harness`를 비활성화하고 `<workspace>/.agents/skills/dev-harness/SKILL.md`만 활성화하는 `skills.config` override를 적용한다. 실행 시작 시 사용자 config를 비공개 임시 snapshot으로 한 번 고정하고, 각 시나리오의 임시 `CODEX_HOME`에 같은 snapshot을 복원한다. 인증 파일은 복사하지 않고 원본을 symlink하며, fixture와 trace에는 포함하지 않는다. trace에는 절대 경로나 config 원문 대신 fixture commit, Skill SHA-256, config SHA-256과 명령 형태만 기록한다.
