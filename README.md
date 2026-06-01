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
├── standards/               # 사고 기준 정의
│   ├── infra.md
│   ├── db.md
│   ├── application.md
│   └── performance.md
├── templates/               # 코드 생성 템플릿
│   ├── sql/
│   ├── mybatis/
│   ├── test/
│   └── api-doc/
├── prompts/                 # 상황별 프롬프트
│   ├── refactor.md
│   ├── performance.md
│   ├── query-review.md
│   └── infra-review.md
└── ci/
    └── prompt-lint.yml
```

현재는 `AGENTS.md`와 `README.md`를 중심으로 시작하고, 필요할 때 기준 문서와 템플릿을 추가한다.

---

## 활용 방식

### 글로벌 설정

```bash
cp AGENTS.md ~/AGENTS.md
```

### 프로젝트별 적용

```bash
ln -s "$(pwd)/AGENTS.md" ./AGENTS.md
```

프로젝트별 규칙이 필요하면 해당 프로젝트의 `AGENTS.md`에서 이 문서를 기반으로 필요한 내용만 오버라이드한다.

---

## 향후 발전 방향

- [ ] Agent별 standards 문서 분리
- [ ] MyBatis, DTO, 테스트 템플릿 추가
- [ ] 응답 품질 체크리스트 자동화
- [ ] 프로젝트별 AGENTS.md 오버라이드 전략 정리
- [ ] Kubernetes 운영 기준 통합
- [ ] Codex 작업 검증 로그 포맷 정리
