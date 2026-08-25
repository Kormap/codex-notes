# DDL 기반 마이그레이션 SQL 생성

source/target DDL 또는 table 구조를 받아 실행 SQL을 설계할 때 이 문서를 읽는다. 제공된 실제 identifier와 DBMS dialect를 보존하며 존재하지 않는 column, constraint, sequence, function을 추정하지 않는다.

## 입력 확인

가능한 범위에서 다음을 확인한다.

- source와 target의 DBMS/version, schema, table DDL;
- TO-BE 프로젝트가 있으면 기준 branch/release, schema migration, persistence mapping과 저장 service;
- primary/unique/foreign key, index, constraint, trigger, sequence/identity, partition;
- column mapping, type·precision·length·charset/collation·time zone 변환;
- code/status mapping, null/default, duplicate/conflict, update/delete/history 보존 규칙;
- source/target row 수, key 분포, 예상 증분량, maintenance window와 허용 부하;
- one-time/backfill/incremental/CDC 여부, source write 지속 여부, consistency/input boundary;
- source와 target의 물리적 연결 topology: 동일 database/schema, DB link/FDW, file/object-storage staging, application ETL 중 승인된 이동 경로와 실행 주체;
- SQL만 실행할지 Java/Spring batch 또는 scheduler에서 chunk로 실행할지.

DDL만으로 결정할 수 없는 업무 규칙은 추정하지 않는다. 결과가 달라지는 미확정 항목은 한 번에 모아 짧게 확인한다. 특히 target business key, source 간 우선순위, ID 생성/보존, delete 처리, null/default, 중복 시 update 허용, 컷오프 기준은 확인 없이 확정하지 않는다.

[field-confirmation.md](field-confirmation.md)에 따라 모든 target field를 분류한다. 질문 전에 가능한 읽기 전용 profiling SQL을 생성해 null/distinct 분포, duplicate business key, orphan FK, 허용되지 않은 code, 길이 초과, precision/overflow, 후보 mapping별 영향 row 수를 확인한다. 실제 결과를 사용할 수 없으면 필요한 query와 결과 입력 형식을 제공하고 `[확인 필요]`로 유지한다.

source와 target을 연결하는 승인된 경로가 확정되지 않으면 cross-system DML을 실행 가능하다고 표시하지 않는다. 대사도 같은 연결에서 수행 가능한지, 별도 extract/checksum 비교가 필요한지 구분한다. credential 값은 요청하거나 출력하지 않고 실행 주체와 권한 범위만 확인한다.

TO-BE 프로젝트 로직이 있으면 [tobe-project-mapping.md](tobe-project-mapping.md)의 근거표를 먼저 작성한다. direct SQL이 converter, listener, validation, event/outbox, cache/index 동기화를 우회하는 경우 SQL 재현·application migration·사후 rebuild 중 어떤 경로를 사용할지 확인받는다.

## 생성 순서

확인 완료 후 필요한 범위만 다음 순서로 제공한다.

1. field inventory와 mapping state/gate 초안
2. source 데이터 품질·중복·orphan·범위와 후보별 영향 row 수 확인용 pre-check SQL
3. `BLOCKING` decision 질문과 사용자 결정 기록
4. 승인된 mapping, 제외 범위와 남은 non-blocking 가정 요약
5. 필요한 staging/cross-reference/run-state/index DDL과 생성 이유
6. migration DML: `INSERT ... SELECT`, `MERGE`, UPSERT 또는 chunk query
7. row count, missing/extra/changed key, aggregate, referential integrity 대사 SQL
8. rerun/idempotency와 실패·reject/redrive 검증 SQL
9. provenance 또는 affected-key/before-image에 근거한 cleanup, rollback 또는 forward-recovery SQL과 point of no return

`BLOCKING` field 또는 `OPEN` decision이 남은 범위에는 migration DML을 생성하지 않는다. 실행 가능한 최종 산출물에는 `TODO`, 임의 identifier, 설명용 placeholder를 남기지 않는다. 사용자에게 정보가 부족하면 SQL을 완성한 척하지 말고 blocker와 필요한 입력을 먼저 제시한다.

## SQL 안전성과 성능

- DBMS/version에 맞는 문법만 사용한다. Oracle `MERGE`, PostgreSQL `ON CONFLICT`, MySQL `ON DUPLICATE KEY UPDATE`를 서로 혼용하지 않는다.
- target의 unique/version constraint 또는 processed-event ledger로 item idempotency를 강제한다. 오래된 source version이 최신 target 값을 역행시키지 않게 한다.
- 대용량 처리는 stable key 기반 keyset range와 고정 upper bound를 사용한다. `OFFSET`, 무제한 full load, row-by-row loop를 기본안으로 두지 않는다.
- chunk size와 commit 단위는 row 크기, index 수, undo/redo/WAL, lock 시간, replication lag를 고려해 근거와 함께 제안한다.
- join/filter/order에 필요한 기존 index를 확인한다. index를 추가하면 column 순서 이유, write overhead, build/lock 방식, 제거 시점을 함께 적는다.
- 함수 적용, 암시적 형변환, 낮은 선택도, 대형 sort/hash/temp, 반복 correlated subquery, 큰 outer row의 nested loop를 점검한다.
- DDL이나 대형 DML이 lock, table rewrite, sequence/identity, trigger, replication, statistics에 미치는 영향을 명시한다.
- 가능한 경우 rehearsal에서 `EXPLAIN`/실행계획과 실제 처리량을 확인한다. 운영 데이터량을 모르면 비용과 완료 시간을 단정하지 않는다.
- rollback/recovery 전에 migration이 insert한 행, 갱신한 기존 행, 이후 정상 application write를 구분할 provenance 또는 affected-key/before-image를 확보한다. 식별 근거 없는 `TRUNCATE`, 무조건 `DELETE`, 광범위 `DROP`을 기본 복구안으로 만들지 않는다. UPSERT 복구에는 승인된 before-image/backup 또는 version-aware forward recovery가 필요하다.

## 실행 검증 gate

최종 SQL은 가능하면 동일 DBMS/version의 격리된 schema 또는 승인된 test 환경에서 parse, constraint 적용, representative fixture 실행, rerun과 recovery를 검증한다. DML은 예상 affected row와 대사 결과를 확인하고 DDL auto-commit 여부도 검증한다. 실행 환경이 없으면 `[생성 완료·실행 미검증]`으로 표시하고 실행 검증 완료와 구분한다. production에서 검증 목적으로 실행하지 않는다.

## 출력 구분

다음 상태를 명확히 표시한다.

- `[확인 필요]`: SQL 의미나 운영 안전성을 바꾸는 미결 사항
- `[승인된 매핑]`: 사용자가 확정한 변환 규칙
- `[사전 점검 SQL]`: 읽기 전용 검증
- `[마이그레이션 SQL]`: 실제 변경 SQL과 transaction/chunk 경계
- `[대사 SQL]`: 동일 input boundary 기준 검증
- `[복구]`: rollback/forward-recovery와 실행 조건

production 실행은 SQL 생성과 별도 승인이다. 생성 요청만으로 schema 변경, target write, cleanup, rollback을 실행하지 않는다.
