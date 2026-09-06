# AGENTS.md - Dev OS for Codex

> 개인 개발 표준을 정의하는 `AGENTS.md` 버전 관리 저장소  
> Codex에서 일관된 구현, 검증, 운영 관점 판단을 수행하기 위한 개발 가이드

> Codex가 읽는 실행 원본은 영어 [`AGENTS.md`](AGENTS.md)이며, 한국어 참고본은 [`docs/AGENTS.ko.md`](docs/AGENTS.ko.md)에서 확인할 수 있다.

---

## 목적

- Codex 응답과 작업 방식에 일관된 행동 규칙 부여
- 질문 복잡도에 따른 출력 강도 자동 조절: FULL / STANDARD / BRIEF
- 응답 프로필 기반 분석 관점과 출력 강도 자동 선택
- 파일 탐색, 수정, 검증, 요약까지 이어지는 Codex 작업 루프 고정
- 원인이 불명확한 운영 장애에서 인프라 -> DB -> 트랜잭션 -> 동시성 -> 코드 순의 기본 조사 프레임 사용

---

## 설계 철학

| 원칙 | 설명 |
|---|---|
| 실행 우선 | 구현 요청은 제안에서 멈추지 않고 가능한 범위에서 직접 수정 |
| 구조 우선 | 코드보다 구조와 책임 경계를 먼저 확인 |
| 검증 필수 | 수정 후 가장 좁은 범위의 테스트/빌드/린트 실행 |
| 운영 기준 | TPS 200+ / 1,000만 row / 10배 스케일 전제 |
| 현실적 | placeholder 금지, 즉시 적용 가능한 코드 작성 |
| 변경 보호 | 사용자 변경사항을 되돌리지 않고 기존 스타일 존중 |

---

## 응답 프로필

질문 맥락에서 분석 관점과 출력 강도를 자동 선택하거나 `[DB]`, `[BACKEND]` 등으로 명시 지정한다. 이 표기는 별도의 에이전트에게 작업을 위임한다는 의미가 아니다.

| 응답 프로필 | 관점 | 대표 상황 |
|---|---|---|
| BACKEND | 트랜잭션, 동시성, 객체 생성, 구조 | Java/Spring, API, 서비스 로직 |
| FRONTEND | 화면 책임, 상태·이벤트 흐름, 접근성, 렌더링 | Vue.js, React, JSP/JSTL 화면, 브라우저 UI |
| DB | 실행 계획, 인덱스, N+1, 비용 추정 | SQL, 조회 성능, slow query |
| INFRA | 배포, 네트워크, 캐싱, 수평 확장, SPOF | Docker, Nginx, EC2, CI/CD |
| BATCH | cursor/chunk, 트랜잭션 분리, 멱등성 | 대용량 처리, 스케줄러, 정산 |
| GENERATOR | DDL/API 스펙 기반 코드 생성 | DTO, VO, MyBatis XML, 테스트 템플릿 |
| LEGACY | 기존 구조 존중, 점진적 개선 | JSP, JSTL, Ant, eGov, WAS |

Java/Spring과 서버 로직은 `[BACKEND · STANDARD]`, Vue.js/React/JSP 화면과 클라이언트 동작은 `[FRONTEND · STANDARD]`를 선택한다. 서버와 화면을 함께 변경하면 `[BACKEND + FRONTEND · STANDARD]`를 사용한다. JSP/JSTL이라도 화면 작업이 중심이면 FRONTEND를, Ant/eGov/WAS 등 레거시 애플리케이션 구조와 운영이 중심이면 LEGACY를 선택한다.

모든 답변 첫 줄에는 적용된 응답 프로필과 강도를 표시한다.

```text
[DB + BACKEND · FULL]
[BACKEND · STANDARD]
[FRONTEND · STANDARD]
[BACKEND + FRONTEND · STANDARD]
[INFRA · STANDARD]
[DEFAULT · BRIEF]
```

---

## 출력 강도

| 강도 | 적용 대상 | 포함 항목 |
|---|---|---|
| FULL | 분석, 설계, 아키텍처, 성능 튜닝 | 병목, 스케일 리스크, 장애 가능성, 개선안, 코드/DDL |
| STANDARD | 코드 리뷰, 버그 수정, 기능 구현 | 문제점, 수정 내용, 코드 예시, 검증 결과 |
| BRIEF | 문법 확인, 개념 질문, 단순 설정 | 핵심 답변만 간결하게 |

---

## Repository Structure

```text
.
├── .githooks/               # pull/push 연동 doctor hook
│   ├── post-merge
│   ├── post-rewrite
│   └── pre-push
├── AGENTS.md                # Dev OS for Codex 본체
├── AGENTS.override.md       # 저장소 전용 계약; 전역 원본 이중 주입 방지
├── .harness/               # 작업 실행·검증·개선을 위한 공통 Harness
│   ├── README.md
│   ├── baseline/           # Harness 대상 작업의 공통 기준
│   ├── tasks/              # 대표 작업의 입력·범위·성공 조건
│   ├── evaluators/         # 작업별 검증 방법과 판정 기준
│   ├── policies/           # 승인 경계와 병렬 작업·파일 소유권 정책
│   ├── roles/              # Lead와 서브에이전트의 실행 역할 계약
│   ├── traces/             # 최소·확장 trace 템플릿과 로컬 실행 기록 계약
│   ├── reports/            # 진단을 통과한 trace의 집계와 candidate 판단 근거
│   └── candidates/         # baseline과 분리해 반복 비교하는 Harness 개선안
├── docs/
│   └── AGENTS.ko.md          # 한국어 참고본
├── README.md                # 저장소 설명
├── scripts/
│   ├── doctor.sh             # 저장소·Harness·Skill·설치 상태 자동 진단
│   ├── test-doctor-harness.sh # doctor Harness-Diagnostics 회귀 테스트
│   └── setup.sh              # Skill symlink·Git hook 최초 설정
└── skills/                  # Codex 개인 Skill
    ├── dev-harness/          # 조건별 Harness 계약을 읽는 runtime router
    ├── engineering-standards/ # 조건별 Java·인프라·batch·legacy 운영 기준
    ├── pr-review/
    ├── spring-transaction-audit/
    ├── query-plan-review/
    ├── jpa-performance-review/
    ├── mybatis-xml-review/
    ├── test-generator/
    ├── logging-observability/
    ├── deploy-checklist/
    ├── data-migration/
    │   ├── README.md
    │   ├── SKILL.md
    │   ├── agents/
    │   │   └── openai.yaml
    │   └── references/
    │       ├── field-confirmation.md
    │       ├── incremental-cdc.md
    │       ├── migration-contract.md
    │       ├── sql-generation.md
    │       ├── spring-scheduler-migration.md
    │       └── tobe-project-mapping.md
    ├── frontend-ui-review/
    │   ├── README.md
    │   ├── SKILL.md
    │   └── references/
    │       ├── jsp.md
    │       ├── vue.md
    │       ├── react.md
    │       └── css-ui.md
    └── skill-list/
```

필요하면 이후 `standards/`, `templates/`, `prompts/`, `ci/`를 추가한다.

---

## Harness

`AGENTS.md`는 공통 행동을 정하고, [`dev-harness`](skills/dev-harness/SKILL.md)는 비단순 구현·리팩터링·설정·버그 수정·검증 중심 리뷰의 필요한 계약을 선택한다. 고위험·반복 품질 평가·멀티에이전트는 변경 크기와 무관하게 적용하며, 그 외 단순 작업은 제외한다. 복합 작업은 주 task와 추가 영역의 필수 evaluator를 함께 적용한다.

상세 색인은 [`.harness/README.md`](.harness/README.md), 공통 기준은 [baseline](.harness/baseline/README.md), 대표 작업은 [tasks](.harness/tasks/README.md), 판정 기준은 [evaluators](.harness/evaluators/README.md), 조건부 승인·병렬 통제는 [policies](.harness/policies/README.md), 역할 계약은 [roles](.harness/roles/README.md)에서 관리한다. Trace 작성 전에는 [실행 계약](.harness/traces/runtime.md)을 읽고, schema·보관·공유는 [traces](.harness/traces/README.md), 집계는 [reports](.harness/reports/README.md), 후보 생성·평가·승격은 [candidates](.harness/candidates/README.md)를 적용한다. Harness 자체 변경 전에는 [유지보수 계약](.harness/maintenance.md)을 읽는다.

Harness-Diagnostics의 현재 실행 진입점은 [`scripts/doctor.sh`](scripts/doctor.sh)다. 필수 Harness 문서와 README 색인, task-evaluator 연결, trace template·로컬 run·report·candidate의 schema, enum과 참조·집계 정합성을 검사한다. 개별 작업의 성공 여부는 evaluator가 판정하며, 여러 trace의 집계와 개선안 판단은 Meta-Harness가 담당한다.

---

## Skills

| Skill | 용도 |
|---|---|
| [`dev-harness`](skills/dev-harness/README.md) | 비단순 개발 작업에서 task, evaluator, trace와 조건부 정책을 선택적으로 로딩 |
| [`engineering-standards`](skills/engineering-standards/README.md) | Java/Spring·인프라·batch·legacy 구현·설계·리뷰와 성능·장애 분석의 조건부 운영 기준 |
| [`pr-review`](skills/pr-review/README.md) | PR 변경점의 버그, 성능, 테스트 누락, 운영 리스크 리뷰 |
| [`spring-transaction-audit`](skills/spring-transaction-audit/README.md) | Spring 트랜잭션, 락, 커넥션 점유, 동시성 점검 |
| [`query-plan-review`](skills/query-plan-review/README.md) | SQL 실행계획, 인덱스, 조인, 페이징 병목 분석 |
| [`jpa-performance-review`](skills/jpa-performance-review/README.md) | JPA N+1, fetch 전략, 영속성 컨텍스트 비용 점검 |
| [`mybatis-xml-review`](skills/mybatis-xml-review/README.md) | MyBatis XML 동적 SQL, resultMap, count/paging 리뷰 |
| [`test-generator`](skills/test-generator/README.md) | JUnit, Mockito, Spring 통합 테스트 생성/보강 |
| [`logging-observability`](skills/logging-observability/README.md) | 로그 레벨, traceId/MDC, 메트릭, 장애 추적성 개선 |
| [`deploy-checklist`](skills/deploy-checklist/README.md) | 배포 전 migration, rollback, config, health check 점검 |
| [`data-migration`](skills/data-migration/README.md) | source/target DDL과 TO-BE 프로젝트 로직 기반 매핑·SQL 생성, 데이터 이전·통합·배치 실행, 대사와 컷오버·복구 점검 |
| [`frontend-ui-review`](skills/frontend-ui-review/README.md) | JSP/JSTL, Vue, React, CSS 구현·리뷰 시 상태 정합성, XSS, 반응형 UI, 브라우저 동작과 시각 회귀 점검 |
| [`skill-list`](skills/skill-list/README.md) | `/스킬` 요청 시 사용 가능한 Codex skill 목록과 로컬 설정 확인 |

각 링크는 상세 설명으로 연결된다. Codex가 실제 실행할 지침의 원본은 각 디렉터리의 `SKILL.md`다. 초기 context에는 skill의 이름·description·경로만 노출되고, 본문과 reference는 선택된 skill에 필요한 범위에서 읽는다.

---

## 활용 방식

### 글로벌 설정

`codex-notes` 저장소의 `AGENTS.md`를 원본으로 두고, Codex의 전역 지침 진입점에 symlink를 둔다.
전역 진입점은 `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`다. `CODEX_HOME`을 설정하지 않으면 기본값은 `~/.codex`다.

```text
${CODEX_HOME:-$HOME/.codex}/AGENTS.md -> /path/to/codex-notes/AGENTS.md
```

새 PC에서는 저장소를 clone한 뒤 전역 진입점을 연결한다. 기존 `AGENTS.md`가 있으면 내용을 먼저 확인하고 백업하거나 통합한 뒤 연결한다.

```bash
git clone https://github.com/Kormap/codex-notes.git /path/to/codex-notes
codex_home=${CODEX_HOME:-"$HOME/.codex"}
mkdir -p "$codex_home"
ln -s /path/to/codex-notes/AGENTS.md "$codex_home/AGENTS.md"
/path/to/codex-notes/scripts/setup.sh
```

`~/AGENTS.md`는 Codex의 표준 전역 discovery 경로가 아니다. 다른 도구가 요구하는 호환 링크로 확인된 경우에만 별도로 유지하며, Codex 설정을 위해 새로 만들지 않는다.

### 프로젝트별 지침

전역 `AGENTS.md`는 모든 프로젝트에 이미 적용되므로 같은 파일을 프로젝트 루트에 다시 symlink하지 않는다. 동일한 원본을 전역과 프로젝트 scope에서 모두 발견하면 지침이 중복 주입된다.

이 저장소는 전역 원본을 버전 관리하므로 프로젝트 진입점으로 [AGENTS.override.md](AGENTS.override.md)를 둔다. 전역 원본이 이미 주입됐으면 재독하지 않고 저장소 전용 계약만 추가한다. 전역 설정이 없는 clone에서는 override가 원본을 한 번 읽도록 안내한다. 새 세션에서 적용되며 기존 대화의 이미 주입된 내용은 제거되지 않는다.

프로젝트별 규칙이 실제로 필요할 때만 해당 프로젝트에 별도의 `AGENTS.md`를 둔다. 더 구체적인 프로젝트 지침과 확립된 관례는 공통 기본값보다 우선하며, 프로젝트 파일에는 빌드·테스트 명령, 도메인 규칙, 배포 제한처럼 프로젝트 고유 정책만 둔다. 하위 디렉터리에 더 좁은 규칙이 필요한 경우에만 그 위치에 local instruction을 추가한다.

예시:

```text
- 기본 언어, 검증 루프, 출력 형식은 유지
- 이 저장소에만 필요한 빌드/테스트 명령, 배포 금지 규칙, 도메인 용어만 추가
```

### Skill 자동 발견

Codex가 개인 Skill을 자동 발견하려면 홈 디렉터리의 Codex Skill 경로 아래에 Skill 디렉터리가 있어야 한다.
공식 사용자 경로인 `~/.agents/skills`에 저장소 Skill 디렉터리의 symlink를 두면, skill 수정사항을 복사 없이 즉시 반영할 수 있다.
복사본을 여러 위치에 두면 저장소 버전과 실제 Codex 사용 버전이 어긋날 수 있으므로 symlink를 기본 방식으로 사용한다.
Windows Git Bash가 권한과 설정에 따라 symlink를 일반 디렉터리로 생성한 경우 doctor는 저장소와 전체 내용이 일치할 때만 이를 허용하며, 한 파일이라도 다르면 실패한다.

`dev-harness`가 일반 디렉터리이면 setup은 중앙 저장소의 절대 POSIX 경로를 `~/.agents/codex-notes-root`에 기록한다. resolver는 symlink의 실제 원본 위치를 우선하고 복사 설치에서만 이 기록을 읽는다. 기존 기록이 다른 저장소를 가리키면 덮어쓰지 않고 실패한다. 저장소를 이동한 경우 기록을 확인·수정한 뒤 setup을 다시 실행한다. 이 로컬 설치 기록은 Git이나 trace에 포함하지 않는다.

저장소를 clone한 직후에는 다음 명령을 한 번 실행한다. 반복 실행해도 이미 올바른 symlink와 hook 설정은 유지된다.

```bash
./scripts/setup.sh
```

setup은 모든 저장소 Skill을 공식 사용자 경로에 연결하고, `core.hooksPath=.githooks` 설정과 doctor 검증까지 수행한다. Windows에서는 저장소와 전체 내용이 같은 일반 디렉터리도 그대로 유지한다. 그 외 기존 일반 파일·디렉터리나 다른 대상을 가리키는 symlink는 덮어쓰지 않고 실패한다.

`.gitattributes`는 shell·hook·Markdown·YAML·텍스트 파일의 checkout 줄바꿈을 LF로 고정한다. 기존 Windows checkout에 남아 있는 CRLF 파일은 로컬 변경을 보존한 뒤 별도로 정규화해야 한다.

아래 명령은 setup을 사용하지 않고 개별 Skill을 수동 연결할 때만 사용한다.

```text
~/.agents/skills/pr-review -> /path/to/codex-notes/skills/pr-review
```

```bash
mkdir -p "$HOME/.agents/skills"
ln -sfn /path/to/codex-notes/skills/pr-review "$HOME/.agents/skills/pr-review"
```

여러 Skill을 한 번에 연결하려면 아래처럼 반복해서 연결한다.

```bash
mkdir -p "$HOME/.agents/skills"
for dir in /path/to/codex-notes/skills/*/; do
  name=$(basename "$dir")
  ln -sfn "$dir" "$HOME/.agents/skills/$name"
done
```

이미 같은 이름의 일반 디렉터리가 있으면 먼저 상태를 확인한 뒤 백업하거나 정리하고, symlink만 `ln -sfn`으로 교체한다.
Skill을 추가하거나 설명을 바꾼 뒤에는 Codex를 재시작하거나 Skill 목록을 다시 읽는 세션에서 확인한다.

### Doctor, Harness-Diagnostics와 Git hook

저장소 구조, Harness 계약, Skill 메타데이터·링크, 공식 사용자 경로의 symlink 또는 Windows 내용 일치 디렉터리와 bundled skill 기준 목록을 한 번에 점검한다.

```bash
./scripts/doctor.sh
```

Harness 검사는 다음 범위를 포함한다.

- 필수 Harness 문서, 루트·하위 README 색인 링크와 현재 baseline 변경 이력
- task/evaluator ID, 파일명, 양방향 연결과 acceptance criteria mapping
- 최소·확장 trace template의 필수 필드·섹션·표 구조
- 존재하는 로컬 trace의 ID, 한국시간 `+09:00`, enum, placeholder와 최종 판정 정합성
- report 템플릿의 필수 필드·표 구조, source inventory·집계 수치와 원본 trace 참조 정합성
- candidate 템플릿의 필수 필드·표 구조, 구현 스크립트와 실제 candidate의 source report·task·evaluator 참조 및 상태·판정 정합성
- 설치된 `dev-harness` resolver가 현재 중앙 저장소를 실제로 찾는지 확인

`doctor.sh`의 Harness 진단 회귀는 Git으로 관리하는 다음 스크립트로 검증한다. 테스트는 임시 저장소 복사본에 정상·오류 fixture를 구성하며 실제 작업 파일을 변경하지 않는다.

```bash
./scripts/test-doctor-harness.sh
sh scripts/test-doc-sync.sh
```

trace template과 진단 테스트는 Git으로 관리하고, 작업별 원본 trace인 `.harness/traces/runs/*.md`는 기본적으로 Git에서 제외한다.

`skill-list` Skill은 호출될 때 doctor를 먼저 실행한다. `setup.sh`가 Git hook을 활성화하므로 push 직전과 pull의 merge/rebase 완료 후에도 doctor가 실행된다.

```bash
./scripts/setup.sh
```

hook만 수동 활성화하려면 `git config --local core.hooksPath .githooks`를 실행한다. 이 설정은 Git으로 공유되지 않으므로 PC별 clone에서 setup을 한 번 실행해야 한다.

- `pre-push`: `scripts/check-doc-sync.sh`가 push 대상 커밋별 영문·한국어 지침 변경을 대조한 뒤 doctor를 실행한다. 오류가 있으면 push를 중단한다. 새 ref는 로컬 remote-tracking ref에 없는 커밋을 검사하고 삭제 ref는 건너뛴다. 번역본 도입 이전 이력은 제외한다. 원격 기준 커밋이 로컬에 없으면 검사를 중단하므로 먼저 해당 원격 이력을 fetch해야 한다.
- `post-merge`: merge 또는 fast-forward pull 완료 후 실행한다.
- `post-rewrite`: rebase pull 완료 후 실행한다.
- 변경이 없는 `git pull`은 Git이 완료 hook을 호출하지 않으므로 doctor가 실행되지 않는다.

---

## Local Codex Automations

반복 작업은 맥미니의 로컬 Codex 자동화를 기본 실행 경로로 둔다.

| 자동화 | 주기 | 결과 |
|---|---|---|
| `Weekly Query Tuning Drill` | 매주 금요일 09:00 KST | Notion `SQL 튜닝 최적화` DB에 문제 5개 생성 또는 로컬 리포트 생성 |
| `Weekly Codex Notes Review` | 매주 월요일 09:00 KST | `codex-notes` 점검 리포트 생성 |

맥미니에서는 위 자동화를 `ACTIVE`로 유지한다.
맥북처럼 상시 실행하지 않는 장비에서는 같은 주기의 로컬 자동화를 `PAUSED` 상태로 유지한다.

Notion/GitHub 연동은 Codex 앱의 커넥터와 로컬 자동화를 통해 수행한다.

---

## 다음 문서

- 장기 개선 항목은 `ROADMAP.md`에서 관리한다.
- Context·지침 수정본의 독립 검토에는 [재검토 프롬프트](docs/context-review-prompt.md)를 사용한다.
