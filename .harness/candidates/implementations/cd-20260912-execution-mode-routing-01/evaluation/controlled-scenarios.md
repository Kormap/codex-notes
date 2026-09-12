# 실행 모드 라우팅 Candidate A 평가 설계

## 상태와 적용 범위

- `contract_id`: `execution-mode-routing-current-request-v1`
- `evaluator_id`: `execution-mode-routing`
- `task_reference`: `current-request:execution-mode-routing-candidate-a`
- `status`: `DESIGN_ONLY`
- `baseline_version`: `0.5.0-domain-skill-routing`

이 문서는 실행 모드 라우팅 Candidate A를 만들기 전에 baseline 증거와 candidate 비교에 공통 적용할 current-request evaluator 및 격리 실행 계약이다. 활성 task/evaluator 색인, `skills/dev-harness/SKILL.md`, baseline version과 사용자 Skill·agent 설치 상태를 변경하지 않는다.

평가 대상은 다음 동작으로 한정한다.

1. 네 전환 gate 판정
2. `MAIN` 또는 `MULTI` 라우팅 결정
3. 플랫폼·상위 지침의 delegation 허용 여부 확인
4. 결정에 맞는 실제 실행 또는 `MAIN_FALLBACK`
5. 역할별 범위와 writer 소유권 전달
6. Lead의 결과 채택과 통합 상태 evaluator 재실행

Custom agent 패키징·설치, trace schema 확장, 역할 계약 변경과 자동 승격은 평가 대상이 아니다.

## 실행 모드 판정 계약

### 네 전환 gate

| Gate | 질문 | `YES` 조건 | `NO` 조건 |
|---|---|---|---|
| `G1` | 독립적으로 완료할 작업 단위가 2개 이상인가? | 둘 이상의 산출물이 상대 작업의 중간 결과 없이 완료 가능 | 단일 작업이거나 앞 단계 결과가 다음 단계 입력 |
| `G2` | 파일·상태·설계 의존성을 분리할 수 있는가? | 읽기 범위 또는 writer 경로가 분리되고 공유 상태 변경이 없음 | 같은 파일·공용 상태·미확정 설계를 함께 다룸 |
| `G3` | 결과 채택 기준과 통합 지점이 명확한가? | 역할별 반환, 채택 기준과 Lead 통합 지점이 사전 정의됨 | 결과 비교·채택·통합 책임이 불명확 |
| `G4` | 병렬화 이득이 조율·통합 비용보다 큰가? | 의미 있는 시간 단축 또는 독립 관점의 발견 품질 향상이 예상됨 | 작업이 짧거나 순차적이고 조율·재검증 비용이 더 큼 |

`routing_decision`은 네 gate가 모두 `YES`일 때만 `MULTI`다. 하나라도 `NO`이거나 근거가 부족하면 `MAIN`으로 판정하고 해당 gate의 사유를 기록한다. 위험도가 높다는 사실만으로 `MULTI`를 선택하거나 writer를 병렬화하지 않는다.

### 실제 실행 값

| `routing_decision` | delegation 조건 | `actual_execution` | 판정 |
|---|---|---|---|
| `MAIN` | 해당 없음 | `MAIN` | 정상 |
| `MULTI` | 허용되고 필요한 collaboration 기능·슬롯 사용 가능 | `MULTI` | 정상 |
| `MULTI` | 플랫폼 또는 상위 지침이 delegation을 금지하거나 필요한 기능·슬롯을 제공하지 않음 | `MAIN_FALLBACK` | fallback 근거와 한계를 충족하면 정상 |
| `MULTI` | 허용되지만 사유 없이 위임하지 않음 | `MAIN` | `FAIL` |
| `MAIN` | 해당 없음 | `MULTI` 또는 `MAIN_FALLBACK` | 과도한 위임으로 `FAIL` |

`MULTI`는 둘 이상의 독립 작업을 실제 delegation하고 Lead가 결과를 채택·통합한 경우다. 역할명을 서술하거나 순차적으로 관점을 바꾼 것만으로 인정하지 않는다.

### `MAIN_FALLBACK` 기준

`MAIN_FALLBACK`은 다음 조건을 모두 만족할 때만 허용한다.

- 네 gate가 모두 `YES`이고 `routing_decision=MULTI`다.
- `fallback_reason`이 `DELEGATION_FORBIDDEN_BY_HIGHER_INSTRUCTION`, `DELEGATION_TOOL_UNAVAILABLE`, `CONCURRENCY_CAPACITY_UNAVAILABLE` 중 하나다.
- 사유를 확인한 상위 지침, 도구 목록 또는 슬롯 상태를 비민감 요약으로 남긴다.
- delegation 시도 자체가 금지된 경우에는 시도하지 않는다. 허용됐지만 기능·슬롯이 일시적으로 불가한 경우에만 안전한 확인 또는 시도 결과를 남긴다.
- 메인 단독 실행으로 사용자 범위와 성공 조건을 충족하고 통합 evaluator를 실행한다.
- `unverified`에 병렬 실행 효과와 역할 독립성을 확인하지 못했음을 기록한다.

Fallback 사유를 확인할 수 없거나 메인 단독으로 필수 성공 조건을 판정할 수 없으면 `BLOCKED`다. 허용된 환경에서 편의상 delegation을 생략하면 fallback이 아니라 `FAIL`이다.

## 통제 시나리오

모든 시나리오는 고정 fixture commit과 아래 요청 본문을 사용한다. 실행 모드를 요청에 직접 지정하지 않는다. 각 실행은 gate 근거, 결정, 실제 실행, 역할별 writable path, 결과 채택, 통합 evaluator와 재작업 횟수를 반환한다.

| ID | 고정 요청 | 기대 gate (`G1/G2/G3/G4`) | 기대 결정 | 추가 불변조건 |
|---|---|---|---|---|
| `SCN-01` | `fixtures/research/source-a.md와 source-b.md를 각각 조사해 주장·근거·한계를 정리하고 공통 결론을 작성하라.` | `YES/YES/YES/YES` | `MULTI` | 두 조사는 서로의 중간 결과를 입력으로 사용하지 않음; writer 없음 |
| `SCN-02` | `fixtures/api의 단일 API 실패를 재현하고 원인을 찾아 최소 수정한 뒤 관련 테스트로 검증하라.` | `NO/NO/YES/NO` | `MAIN` | 재현→원인→수정→검증이 순차 의존; 동일 모듈 단일 writer |
| `SCN-03` | `fixtures/review/change.diff를 보안·성능·회귀 관점에서 검토하고 재현 가능한 finding만 통합하라.` | `YES/YES/YES/YES` | `MULTI` | 각 관점은 읽기 전용; finding 채택 기준은 파일·라인·영향·재현 근거 |
| `SCN-04` | `fixtures/shared의 공용 설정과 연결된 migration을 일관되게 변경하고 검증하라.` | `YES/NO/YES/NO` | `MAIN` | 두 변경 단위가 같은 계약에 결합됨; 공용 파일·migration writer는 하나 |
| `SCN-05` | `fixtures/module-a와 module-b의 독립 결함을 각각 수정하고 각 모듈 테스트 후 통합 검증하라.` | `YES/YES/YES/YES` | `MULTI` | 설계가 고정됨; writer 경로는 `fixtures/module-a/**`, `fixtures/module-b/**`로 비중첩 |

Fixture는 네 작업 유형을 실제로 판정할 수 있는 최소 파일과 로컬 검증 명령을 포함해야 한다. 네트워크, 외부 계정, 운영 데이터와 외부 상태 변경에 의존하면 안 된다. `SCN-01`, `SCN-03`은 읽기 전용이고 `SCN-02`, `SCN-04`, `SCN-05`의 변경은 격리 workspace 밖으로 나가면 안 된다.

## Current-request evaluator

### 성공 조건

- `AC-ROUTING-01`: 다섯 시나리오의 gate와 `routing_decision`이 고정 기대값과 일치한다.
- `AC-ROUTING-02`: `actual_execution`이 결정 및 delegation 허용 상태와 일치하고 fallback이 허용 조건을 충족한다.
- `AC-ROUTING-03`: 역할 범위와 writer 소유권이 사전 배정되고 경로 중첩·범위 밖 변경이 없다.
- `AC-ROUTING-04`: Lead가 역할 결과를 명시적으로 채택·기각하고 통합 상태에서 evaluator를 다시 실행한다.
- `AC-ROUTING-05`: baseline과 candidate가 Skill 내용 외에는 같은 입력·환경·판정 기준을 사용하며 사용자 설치와 활성 baseline을 오염시키지 않는다.

### 검사

| 검사 ID | 연결 조건 | 필수 여부 | 방법 |
|---|---|---|---|
| `EV-ROUTING-01` | `AC-ROUTING-01` | `REQUIRED` | 다섯 시나리오별 기대 gate·결정과 trace의 실제 값을 대조 |
| `EV-ROUTING-02` | `AC-ROUTING-02` | `REQUIRED` | 결정·delegation 허용 상태·실제 실행 조합 및 fallback 근거 대조 |
| `EV-ROUTING-03` | `AC-ROUTING-03` | `REQUIRED` | assignment의 writable path와 실행 전후 변경 파일을 대조 |
| `EV-ROUTING-04` | `AC-ROUTING-04` | `REQUIRED` | delegation 반환, Lead 채택 판단과 통합 evaluator 결과 대조 |
| `EV-ROUTING-05` | `AC-ROUTING-05` | `REQUIRED` | snapshot hash, 실행 옵션, fixture commit, Skill catalog와 사용자 경로 상태 대조 |

### 검사별 판정

각 검사는 다음 공통 우선순위로 판정한다.

- `PASS`: 연결된 성공 조건을 모든 적용 시나리오에서 확인했다.
- `FAIL`: 실행 가능한 시나리오에서 기대값 불일치, 허용되지 않은 fallback, 경로 중첩·범위 밖 변경, 통합 검증 누락 또는 격리 오염이 확인됐다.
- `BLOCKED`: fixture·플랫폼 상태·실행 기록이 없어 필수 조건을 신뢰성 있게 판정할 수 없고 허용된 대체 근거도 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

`EV-ROUTING-02`에서 적법한 `MAIN_FALLBACK`은 `PASS`로 판정하되 병렬화 효과를 `unverified`로 기록한다. `EV-ROUTING-04`의 통합 evaluator는 역할별 검증과 별개이며 Lead가 최종 workspace에서 재실행해야 한다.

### 전체 판정

- `PASS`: 다섯 필수 검사가 모두 `PASS`다.
- `FAIL`: 하나 이상의 필수 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 검사가 `BLOCKED`다.

Baseline 증거 단계에서는 시나리오별 evaluator 판정과 별도로 “네 gate를 만족한 입력에서 실행 모드 판단 또는 delegation 시도가 누락됐는가”를 신호로 집계한다. `MAIN_FALLBACK` 표본은 자동 라우팅 누락 횟수에서 제외하고 병렬 효과 비교에도 사용하지 않는다.

## Trace 반환 계약

기존 extended trace schema를 유지한다. 별도 필드를 추가하지 않고 `evaluator_results`의 `command_or_method`에 아래 키를 같은 순서로 기록한다.

```text
scenario=SCN-01;
g1=YES; g2=YES; g3=YES; g4=YES;
routing_decision=MULTI;
delegation_allowed=false;
actual_execution=MAIN_FALLBACK;
fallback_reason=DELEGATION_FORBIDDEN_BY_HIGHER_INSTRUCTION;
writer_overlap=false;
integration_evaluator=PASS;
rework_count=0
```

`agent_assignments`, `delegations`, `ownership_conflicts`, `integration_verification`, `unverified`는 extended trace의 기존 위치에 기록한다. `MAIN` 실행에서 멀티에이전트 섹션은 `NOT_APPLICABLE`로 유지한다. `MAIN_FALLBACK`은 delegation을 수행하지 않았으므로 assignment와 delegation은 `NOT_APPLICABLE`로 두고 fallback 근거를 evaluator 결과와 `unverified`에 남긴다.

## Candidate 격리 실행 계약

### Baseline 평가 자산

Candidate 생성 전 baseline 증거용 통제 입력과 실행 도구는 `.harness/evaluations/execution-mode-routing/`에 둔다. 이 경로는 활성 baseline이나 candidate 구현이 아니며 다음 자산만 포함한다.

- 다섯 고정 요청과 여섯 fixture 경로
- 결정적 fixture commit 생성 스크립트와 commit 식별자
- 시나리오별 로컬 통합 검증 명령
- `routing-result.schema.json`과 routing contract validator
- 실행별 Skill catalog/hash, resolver, config digest와 collaboration 기능 preflight

사용자 config는 baseline 묶음 시작 시 비공개 임시 snapshot으로 한 번 고정하고 각 실행별 임시 `CODEX_HOME`에 복원한다. 인증 파일은 복사하지 않고 원본을 symlink하며 fixture, trace와 report에 원문이나 절대 경로를 남기지 않는다. 이 자산으로 수집한 baseline trace와 이후 candidate trace는 같은 fixture commit, config digest와 실행 옵션을 사용한다.

### 격리 구조

Source report가 Candidate 생성 조건을 충족한 뒤에만 다음 구조를 만든다.

```text
.harness/candidates/
├── cd-YYYYMMDD-execution-mode-routing-01.md
└── implementations/
    └── cd-YYYYMMDD-execution-mode-routing-01/
        ├── skills/
        │   └── dev-harness/
        │       └── SKILL.md
        └── evaluation/
            ├── controlled-scenarios.md
            ├── routing-result.schema.json
            └── validate-routing-contract.sh
```

이번 평가 설계 단계에서는 위 경로를 생성하지 않는다. Candidate 파일과 구현 디렉터리는 source report가 `CREATE/READY/OPEN`을 충족한 후 생성한다.

### 실행 격리

각 비교 쌍은 임시 루트 아래에 같은 fixture commit으로 baseline workspace와 candidate workspace를 각각 만든다. 두 workspace의 `.agents/skills/dev-harness/SKILL.md`에는 각각 활성 baseline snapshot과 candidate snapshot 하나만 배치한다. Codex가 repository의 `.agents/skills`를 탐색하는 현재 discovery 계약을 사용하되 다음 preflight를 통과해야 한다.

- 사용 가능한 Skill catalog에서 `dev-harness`가 정확히 하나다.
- catalog의 `SKILL.md` SHA-256이 해당 실행의 고정 snapshot hash와 같다.
- 개인 설치 경로의 동일 이름 Skill은 실행별 config override로 비활성화한다.
- config override 후에도 중복 Skill이 보이거나 선택된 hash를 확인할 수 없으면 실행하지 않고 `BLOCKED`다.

Repository Skill 위치는 [OpenAI Build skills 문서](https://learn.chatgpt.com/docs/build-skills)의 `.agents/skills` discovery 계약을 따른다. 실행 명령은 다음 형태로 고정한다.

```text
codex exec --ephemeral --json \
  -C <isolated-workspace> \
  -m <fixed-model> \
  -c 'model_reasoning_effort="<fixed-effort>"' \
  -c 'skills.config=[
    {path="<personal-dev-harness>/SKILL.md",enabled=false},
    {path="<isolated-workspace>/.agents/skills/dev-harness/SKILL.md",enabled=true}
  ]' \
  --output-schema <routing-result.schema.json> \
  <scenario-prompt>
```

사용자 `config.toml`을 완전히 무시하면 collaboration 기능까지 달라질 수 있으므로 baseline과 candidate가 같은 사용자 config digest를 사용하고, 위 override로 비교 대상 Skill 경로만 바꾼다. 실제 명령과 config digest는 baseline 증거 작업의 trace에 절대 사용자 경로와 민감정보를 제외한 재실행 가능한 형태로 기록한다.

### 비교 불변조건

Baseline과 candidate의 한 비교 쌍에서 다음 값은 같아야 한다.

- fixture commit과 시나리오 요청 본문
- 모델과 reasoning effort
- sandbox·approval·네트워크 조건
- collaboration 기능과 동시 슬롯 한도
- 역할 문서, evaluator와 성공 조건
- timeout과 허용 재시도 횟수
- 출력 schema와 결과 정규화 방법

달라질 수 있는 것은 `dev-harness/SKILL.md` snapshot뿐이다. 실행 순서 편향을 줄이기 위해 비교 쌍마다 baseline/candidate 시작 순서를 교대하고 각 실행은 새 ephemeral session을 사용한다.

### 오염 방지와 종료 확인

- 실제 `~/.agents/skills`, `~/.codex/agents`, 활성 `skills/dev-harness/SKILL.md`와 baseline version을 수정하지 않는다.
- 사용자 설정, 인증 파일과 session 원문을 fixture나 trace에 복사하지 않는다.
- 실행 전후 활성 저장소 `git status --short`, 대상 파일 hash와 사용자 설치 경로 상태를 비교한다.
- 모든 writer는 해당 격리 workspace의 배정 경로만 수정한다.
- 임시 workspace 정리는 결과·hash·trace 저장 확인 후 수행하며 실패 시 경로와 복구 필요 상태를 보고한다.
- 활성 저장소 또는 사용자 설치 상태가 바뀌면 `EV-ROUTING-05=FAIL`이고 후속 비교를 중단한다.

## 다음 요청의 진입 조건

Baseline 증거 수집은 다음이 모두 충족될 때 시작할 수 있다.

- 다섯 fixture와 로컬 검증 명령이 준비됨
- Skill catalog/hash preflight 방법이 실제 환경에서 확인됨
- extended trace에 위 반환 값을 기록할 수 있음
- 플랫폼 delegation 허용 여부를 실행별로 증명할 방법이 있음
- 활성 저장소와 사용자 설치 경로의 전후 상태 확인 방법이 준비됨

이 중 하나라도 없으면 해당 baseline 실행을 `BLOCKED`로 기록한다. Candidate나 source report를 미리 만들지 않는다.
