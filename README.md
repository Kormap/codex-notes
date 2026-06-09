# AGENTS.md - Dev OS for Codex

> 개인 개발 표준을 정의하는 `AGENTS.md` 버전 관리 저장소  
> Codex에서 일관된 구현, 검증, 운영 관점 판단을 수행하기 위한 개발 가이드

---

## 목적

- Codex 응답과 작업 방식에 일관된 행동 규칙 부여
- 질문 복잡도에 따른 출력 강도 자동 조절: FULL / STANDARD / BRIEF
- Agent Mode 기반 분석 관점 자동 전환
- 파일 탐색, 수정, 검증, 요약까지 이어지는 Codex 작업 루프 고정
- 인프라 -> DB -> 트랜잭션 -> 동시성 -> 코드 순 문제 해결 프레임 유지

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

## Agent Mode

질문 맥락에서 자동 추론하거나 `[DB]`, `[BACKEND]` 등으로 명시 지정한다.

| Agent | 관점 | 대표 상황 |
|---|---|---|
| BACKEND | 트랜잭션, 동시성, 객체 생성, 구조 | Java/Spring, API, 서비스 로직 |
| DB | 실행 계획, 인덱스, N+1, 비용 추정 | SQL, 조회 성능, slow query |
| INFRA | 배포, 네트워크, 캐싱, 수평 확장, SPOF | Docker, Nginx, EC2, CI/CD |
| BATCH | cursor/chunk, 트랜잭션 분리, 멱등성 | 대용량 처리, 스케줄러, 정산 |
| GENERATOR | DDL/API 스펙 기반 코드 생성 | DTO, VO, MyBatis XML, 테스트 템플릿 |
| LEGACY | 기존 구조 존중, 점진적 개선 | JSP, JSTL, Ant, eGov, WAS |

모든 답변 첫 줄에는 적용된 Agent와 강도를 표시한다.

```text
[DB + BACKEND · FULL]
[BACKEND · STANDARD]
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
├── AGENTS.md                # Dev OS for Codex 본체
├── README.md                # 저장소 설명
└── skills/                  # Codex 개인 Skill
    ├── pr-review/
    ├── spring-transaction-audit/
    ├── query-plan-review/
    ├── jpa-performance-review/
    ├── mybatis-xml-review/
    ├── test-generator/
    ├── logging-observability/
    ├── deploy-checklist/
    └── skill-list/
```

필요하면 이후 `standards/`, `templates/`, `prompts/`, `ci/`를 추가한다.

---

## Skills

| Skill | 용도 |
|---|---|
| `pr-review` | PR 변경점의 버그, 성능, 테스트 누락, 운영 리스크 리뷰 |
| `spring-transaction-audit` | Spring 트랜잭션, 락, 커넥션 점유, 동시성 점검 |
| `query-plan-review` | SQL 실행계획, 인덱스, 조인, 페이징 병목 분석 |
| `jpa-performance-review` | JPA N+1, fetch 전략, 영속성 컨텍스트 비용 점검 |
| `mybatis-xml-review` | MyBatis XML 동적 SQL, resultMap, count/paging 리뷰 |
| `test-generator` | JUnit, Mockito, Spring 통합 테스트 생성/보강 |
| `logging-observability` | 로그 레벨, traceId/MDC, 메트릭, 장애 추적성 개선 |
| `deploy-checklist` | 배포 전 migration, rollback, config, health check 점검 |
| `skill-list` | `/스킬` 요청 시 사용 가능한 Codex skill 목록과 로컬 설정 확인 |

---

## 활용 방식

### 글로벌 설정

`codex-notes` 저장소 루트에서 실행한다.

```bash
cp AGENTS.md ~/AGENTS.md
```

### 프로젝트별 적용

적용할 프로젝트 디렉터리에서 실행한다.

```bash
ln -s /path/to/codex-notes/AGENTS.md ./AGENTS.md
```

프로젝트별 규칙이 필요하면 해당 프로젝트의 `AGENTS.md`에서 이 문서를 기반으로 필요한 내용만 오버라이드한다.

### Skill 자동 발견

Codex가 개인 Skill을 자동 발견하려면 홈 디렉터리의 Codex Skill 경로 아래에 Skill 디렉터리가 있어야 한다.
이 저장소를 원본으로 유지하고 `~/.codex/skills`에는 symlink를 두면, skill 수정사항을 복사 없이 즉시 반영할 수 있다.
복사본을 여러 위치에 두면 저장소 버전과 실제 Codex 사용 버전이 어긋날 수 있으므로 symlink를 기본 방식으로 사용한다.

```text
~/.codex/skills/pr-review -> /path/to/codex-notes/skills/pr-review
```

```bash
ln -s /path/to/codex-notes/skills/pr-review "$HOME/.codex/skills/pr-review"
```

여러 Skill을 한 번에 연결하려면 아래처럼 반복해서 연결한다.

```bash
mkdir -p "$HOME/.codex/skills"
for dir in /path/to/codex-notes/skills/*; do
  name=$(basename "$dir")
  ln -s "$dir" "$HOME/.codex/skills/$name"
done
```

이미 같은 이름의 링크나 디렉터리가 있으면 먼저 상태를 확인한 뒤 교체한다.
Skill을 추가하거나 설명을 바꾼 뒤에는 Codex를 재시작하거나 Skill 목록을 다시 읽는 세션에서 확인한다.

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
