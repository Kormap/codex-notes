# data-migration

AS-IS/TO-BE DDL, 실제 데이터 분포와 TO-BE 프로젝트 로직을 근거로 field mapping을 확정하고 안전한 데이터 이전을 설계·검증하는 스킬이다.

## 주요 입력

- source/target DDL과 DBMS/version
- key·FK·constraint·index·sequence/identity 정보
- 대략적인 row 수와 데이터 변경 여부
- one-time, backfill, incremental 또는 CDC 실행 방식
- 가능한 경우 TO-BE 프로젝트 경로와 기준 branch/release

## 산출물

| 산출물 | 제공 내용 |
|---|---|
| Field mapping 계약 | source→target column, 변환/default, key·FK 관계, null·status·delete 규칙, 근거, 확정 상태와 사용자 decision 기록 |
| 확인 필요 목록 | 애매한 field, 선택지별 영향, 영향 row 수, 권고 근거와 차단 범위 |
| Profiling·사전 점검 SQL | null/distinct 분포, business key 중복, orphan FK, code/status 분포, 길이·precision 초과, 변환 실패와 예상 대상 건수 |
| 마이그레이션 SQL | DBMS/version에 맞는 `INSERT ... SELECT`, `MERGE`, UPSERT, staging/cross-reference DDL, keyset chunk query |
| Java/Spring 실행 설계·코드 | Spring Batch 또는 `@Scheduled` 기반 chunk, transaction, lock, checkpoint, retry/reject와 idempotency 구현 |
| 대사 SQL과 판정 기준 | row count, missing/extra/changed key, FK 무결성, 집계·금액, reject와 rerun 검증 |
| 복구·운영 산출물 | rollback/forward-recovery SQL, affected-key/before-image, cutover runbook, stop/go 조건과 monitoring query |

## 확인 원칙

DDL·코드·데이터 분포로 확정할 수 있는 것은 스킬이 먼저 분석한다. 업무 의미가 여러 가지이거나 데이터 손실 가능성이 있는 항목만 선택지와 영향을 제시해 사용자에게 확인한다. `BLOCKING` 결정이 남은 범위에는 최종 migration SQL/code를 제공하지 않으며, mapping 승인과 production 실행 승인은 별도다.

실행 지침은 [SKILL.md](SKILL.md), field 확인 기준은 [references/field-confirmation.md](references/field-confirmation.md), SQL 생성 기준은 [references/sql-generation.md](references/sql-generation.md)를 확인한다.
