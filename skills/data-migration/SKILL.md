---
name: data-migration
description: 하나 이상의 source에서 하나 이상의 target으로 데이터를 안전하게 이전·통합·재구성하는 데이터 마이그레이션을 설계·구현·검증할 때 사용한다. 스키마 매핑, ETL/SQL, backfill·incremental·CDC, 리허설, 대사, 컷오버와 복구 계획에 적용한다. 매핑·재실행·대사·운영 전환 설계가 필요 없는 로컬 단순 복사에는 사용하지 않는다.
---

# 데이터 마이그레이션

승인된 매핑 계약 없이 업무 의미를 변경하지 않는다. 모든 마이그레이션에는 안전한 중지와 rollback 또는 검증된 forward-recovery 경로가 있어야 한다. 완전한 역변환이 불가능하면 point of no return과 restore/switchback 전략을 명시한다. 컷오버가 명시적으로 승인되기 전까지 source 데이터는 읽기 전용으로 취급한다.

## 최우선 원칙: 데이터 정확성과 확인 gate

마이그레이션 SQL 생성 자체보다 각 target field의 업무 의미와 데이터 정합성을 확정하는 일을 우선한다. DDL, 데이터 분포, TO-BE 프로젝트 로직을 근거로 field를 분류하고, 애매하거나 사용자의 업무 결정이 필요한 항목은 [references/field-confirmation.md](references/field-confirmation.md)에 따라 확인한다.

- required field, business/primary key, foreign key, status/code, 금액·단위·precision, 날짜·time zone, tenant/owner, 개인정보·보안, audit/history, delete 정책처럼 결과를 바꾸는 미결 항목은 `BLOCKING`으로 취급한다.
- `BLOCKING` 항목이 남아 있는 범위에는 실행 가능한 최종 migration SQL 또는 target write code를 만들거나 실행하지 않는다. 확인된 subset만 진행하려면 범위와 제외 항목을 사용자가 명시적으로 승인해야 한다.
- 미확정 field에 임의 source, default, null, 첫 번째 값, 최신 값 또는 추정 변환을 적용하지 않는다.
- 가능한 경우 질문 전에 읽기 전용 profiling SQL로 null, distinct value, duplicate, orphan, 범위·길이·precision, 후보 규칙별 영향 row 수를 확인한다. 민감한 원문 값은 노출하지 않는다.
- mapping 결정 승인과 production 실행 승인은 별도 gate다. 사용자가 mapping을 확정해도 production DML/DDL 실행이 자동 승인된 것은 아니다.

## 매핑 계약부터 확정

SQL이나 코드를 제안하기 전에 AS-IS 스키마, TO-BE 스키마, 데이터량, primary/unique key, foreign key, 코드 테이블, 상태값, timestamp/time zone, 개인정보·민감 컬럼을 확인한다. 초안 설계에서는 미확정 항목을 assumption/TBD로 분리할 수 있지만, production 구현·실행 전에는 중요한 매핑과 acceptance criteria를 승인받는다.

모든 source와 target을 포괄하는 매핑 계약을 작성하고 실행 수명·가용성·변경 전달·쓰기 소유권을 독립적으로 선택한다. 상세 템플릿은 [references/migration-contract.md](references/migration-contract.md)를 읽는다. 각 target field에는 mapping state, evidence, gate와 필요한 decision ID를 기록한다. 식별자, 상태/코드 변환, 데이터 소유권, 이력 보존, null/default 규칙은 추정하지 말고 사용자 결정 사항으로 분리한다. 여러 source가 동일 업무 entity를 제공할 때만 충돌 우선순위를 추가로 확정한다.

사용자가 source/target DDL 또는 table 구조를 제공하고 마이그레이션 SQL 생성을 요청하면 [references/sql-generation.md](references/sql-generation.md)를 읽는다. DBMS/version, key와 relationship, column mapping, 데이터량, source 변경 가능성, conflict·null·delete 규칙처럼 결과를 바꾸는 항목이 불명확하면 필요한 확인 질문만 먼저 한다. 확인 전에는 assumption/TBD가 표시된 초안만 제공하고, 실행 가능한 최종 SQL에는 placeholder나 미확정 규칙을 남기지 않는다.

TO-BE 프로젝트 코드가 제공되거나 접근 가능하고 field mapping 또는 실제 load semantics를 확정해야 하면 DDL만으로 매핑을 확정하지 말고 [references/tobe-project-mapping.md](references/tobe-project-mapping.md)를 읽는다. persistence mapping과 업무 로직에서 target 값의 생성·정규화·검증·암호화·상태 전이·audit 규칙을 추적해 AS-IS column mapping 근거로 사용한다. DDL, persistence mapping, service 규칙이 서로 다르면 충돌을 숨기지 말고 사용자 확인 후 확정한다.

## 재실행성과 추적성 설계

- source가 중복되거나 ID를 재발급하는 경우, 각 source 레코드의 출처와 원래 업무 식별자를 audit/cross-reference 구조에 보존한다.
- 변환 규칙은 결정적으로 유지한다. 재실행해도 TO-BE 중복 행이 생성되거나 더 최신 데이터를 조용히 덮어쓰면 안 된다.
- 각 source별로 일관된 추출 경계와 update/delete 전달 규칙을 정의한다. mutable source, online backfill, incremental 또는 CDC가 포함되면 [references/incremental-cdc.md](references/incremental-cdc.md)를 읽는다.
- 대용량 테이블은 명시적인 checkpoint와 고정 input boundary를 가진 keyset 기반 chunk로 처리한다. `OFFSET` paging과 제한 없는 메모리 적재는 피한다.
- run identity와 item identity를 분리한다. item idempotency는 migration version, source, source key/version 또는 event position, target action을 식별하고 target의 unique/version constraint나 processed-event ledger로 강제한다.
- 변환 실패는 추적 가능해야 한다. source system, source key, 알 수 있는 경우 target key, 처리 단계, 사유, retry 상태를 기록하고 반려 행을 버리지 않는다.
- 외부 API 호출과 장시간 export는 DB transaction 밖에서 처리한다. transaction 범위는 batch 단위로 제한한다.

## Spring scheduler로 실행할 때

`scheduler`는 오케스트레이터로만 사용하고 마이그레이션 상태의 원본으로 사용하지 않는다. 주기 실행하거나 여러 작업 창에 걸쳐 재개해야 한다면, job을 설계하기 전에 [references/spring-scheduler-migration.md](references/spring-scheduler-migration.md)를 읽는다.

- job 실행, source 범위/checkpoint, 처리 건수, 실패 사유, 완료 상태를 DB에 영속화한다. 메모리 counter와 cron expression은 복구 수단이 아니다.
- 동일 migration version과 source partition/range의 중복 소유를 막기 위해 DB 기반 lock 또는 배포 환경에 맞는 distributed lock을 사용한다. 의도적으로 분리된 partition의 병렬 실행은 허용한다. cluster 환경에서 JVM 내부 `synchronized`만으로는 부족하다.
- 모든 scheduled run에 안정적인 idempotency key를 부여한다. 동일 tick이나 일부만 처리된 chunk를 재실행해도 중복 insert 또는 동일 업무 상태 전이가 발생하면 안 된다.
- 각 chunk는 작고 독립적으로 처리한다. target write와 run-state가 같은 transactional resource이면 처리 결과와 checkpoint를 함께 commit한다. 서로 다르면 at-least-once 재전달과 item idempotency를 적용하고 durable target 성공 확인 후 checkpoint를 전진시킨다. 전체 마이그레이션을 하나의 transaction으로 묶지 않는다.
- 분류된 transient failure에만 횟수가 제한된 retry와 backoff를 적용한다. validation 또는 mapping 실패는 무한 재시도하지 않고 검토 대상으로 보관한다.
- pause, resume, cancel, graceful shutdown 동작을 명시한다. 중지된 instance는 권한 있는 다른 instance가 안전하게 재개할 수 있는 영속 checkpoint를 남겨야 한다.

framework가 관리하는 재시작, item 단위 skip/retry, partitioning이 필요하면 `Spring Batch`를 선택한다. job 상태, locking, chunking, 대사 규칙을 명시적으로 구현할 수 있을 때만 집중된 `@Scheduled` service를 사용한다. 단지 schedule로 실행한다는 이유만으로 `Spring Batch`를 추가하지 않는다.

## 컷오버 전 검증

가능하면 운영과 유사한 snapshot으로 리허설을 만들고 실행한다. 다음 합의된 acceptance criteria를 통과한 뒤에만 마이그레이션 준비가 완료된 것으로 판단한다.

1. 적재 후 schema와 constraint 검증을 통과한다.
2. 동일 snapshot/watermark/CDC position과 매핑 계약의 기대 cardinality를 기준으로 source-to-target이 대사된다.
3. 금액 또는 집계값이 있는 entity는 총계와 잔액이 대사된다.
4. missing/extra/changed business key, 관계 위반, conflict/reject disposition을 확인한다.
5. 반려 행은 0건이거나 명시적으로 승인된 처리 방침이 있다.
6. 동일한 고정 input boundary로 batch를 재실행해도 idempotent하고 최신 target 값을 역행시키지 않는다.
7. 컷오버 시간은 승인된 maintenance window에 맞고 rollback 소요 시간을 안다.

정확한 query 결과와 불일치를 보고한다. 예외 없이 끝났다는 이유만으로 검증 완료라고 판단하지 않는다.

## 컷오버와 롤백

담당자, timestamp, 사전 조건, stop/go 기준, monitoring query, 명시적 복구 방법을 포함한 runbook을 제안한다. production target load, schema/constraint/index/grant 변경, CDC connector·replication slot·trigger·log-retention 변경, dual-write, source write freeze, read/write routing 전환, cleanup, rollback/restore는 각각 운영 변경으로 취급한다. 실행 직전에 environment, exact target, 데이터 범위, 예상 건수·시간·부하, 승인자, stop condition과 복구 경로를 확인받는다. 운영 데이터 export와 리허설 복제도 개인정보·보존·폐기 승인을 확인한다.

단계적 또는 dual-write 컷오버에서는 entity별 system of record와 충돌 탐지·해결 방식을 명시한다. 명시적 요청 없이는 dual-write를 활성화하거나 AS-IS 데이터를 삭제하지 않는다.

## 산출물

요청 범위에 맞는 산출물만 제공한다. 일반적으로 매핑 계약, consistency/input boundary, 마이그레이션 설계(SQL/ETL 또는 application batch), 사전 점검·실행·대사·복구 SQL, dry-run 보고서, 컷오버/복구 runbook을 제공한다. scheduler 기반 작업에는 run-state schema, lock 전략, checkpoint 의미, retry/skip/redrive 정책, 운영 제어도 포함한다. 가정과 미결 매핑 결정은 승인된 규칙과 분리한다.
