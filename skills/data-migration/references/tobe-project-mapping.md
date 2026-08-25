# TO-BE 프로젝트 로직 기반 매핑

TO-BE 프로젝트 코드가 제공되면 이 문서를 읽고 실제 저장 의미와 생성 규칙을 AS-IS column mapping에 반영한다. 파일명이나 DTO 이름만으로 판단하지 말고 저장 경로를 끝까지 추적한다.

## 조사 순서

1. target DDL, constraint, index, trigger, sequence/identity와 Flyway/Liquibase migration을 확인한다.
2. JPA Entity/Embeddable 또는 MyBatis `resultMap`, mapper interface/XML, DTO/VO, `TypeHandler`를 확인한다.
3. create/update service, factory, assembler, converter, enum/code mapping, validation과 transaction boundary를 추적한다.
4. 실제 insert/update SQL 또는 ORM 생성 SQL에서 최종 저장 column과 값을 확인한다.
5. 관련 test와 fixture에서 정상값·경계값·상태 전이 기대값을 확인한다. test가 현재 DDL/코드와 다르면 근거로 확정하지 않는다.

JPA에서는 `@Column`, `@Embedded`, association/FK, `@Enumerated`, `AttributeConverter`, `@PrePersist`/`@PreUpdate`, auditing, `@Version`, ID generator를 확인한다. MyBatis에서는 `resultMap`, dynamic SQL, `#{}` parameter, `TypeHandler`, SQL fragment, DB별 분기를 mapper와 호출 service까지 함께 읽는다.

## 반드시 식별할 로직

- business key와 ID 생성/보존 방식;
- enum/code/status 변환과 허용 상태 전이;
- null/default, trim/case, 정규화, 단위·금액·precision, time zone 규칙;
- password/hash, encryption, masking, 개인정보·민감값 처리;
- tenant/owner, audit field, soft delete, version, history 유효기간;
- derived/denormalized column, aggregate, search field, relation/FK 생성;
- outbox/domain event, cache/index 동기화처럼 direct SQL이 우회하는 side effect.

hash/encryption key, secret, production 개인정보는 출력하거나 fixture로 복사하지 않는다. 필요한 경우 기존 secret-management와 application API/service 경로를 사용하도록 설계한다.

## 매핑 근거표

AS-IS field마다 다음 근거를 남긴다.

| AS-IS table.column | TO-BE table.column | 프로젝트 근거 file:symbol | 적용 로직 | SQL 직접 변환 가능 여부 | Mapping state | Gate | Decision ID | 확인/검증 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | SQL / application required / 확인 필요 | `UNRESOLVED` | `BLOCKING` / `NON_BLOCKING` | | |

근거는 가능한 한 실제 file과 class/method/mapper statement를 지정한다. API DTO나 화면 label은 저장 의미의 보조 근거일 뿐, DDL·persistence mapping·저장 service보다 우선하지 않는다.
상태와 사용자 확인 방식은 [field-confirmation.md](field-confirmation.md)를 사용한다. 코드에서 발견한 후보 규칙이 유일해 보여도 DDL, 운영 데이터 분포 또는 다른 저장 경로와 충돌하면 `UNRESOLVED`로 유지하고 decision ID를 부여한다.

## Direct SQL과 application 경로 선택

- direct SQL은 Entity listener, converter, validation, domain event, outbox, cache 갱신을 자동 실행하지 않는다.
- 해당 동작이 target 정합성에 필요하면 SQL에서 검증 가능하게 재현하거나 Java/Spring migration service를 사용한다.
- application 경로를 사용하면 일반 API의 per-row 호출을 그대로 반복하지 말고 bulk/chunk 처리, transaction 범위, idempotency, N+1과 persistence context 크기를 설계한다.
- side effect가 마이그레이션에서 불필요하다면 생략 여부와 사후 rebuild/reindex 절차를 사용자에게 확인받는다.
- DDL과 코드가 불일치하거나 여러 저장 경로가 다른 규칙을 적용하면 임의로 하나를 선택하지 않는다. active production path, 적용 version, migration 기준 시점을 확인한다.

## 산출물과 확인 gate

먼저 `[프로젝트 근거]`, `[AS-IS→TO-BE 매핑]`, `[불일치/확인 필요]`, `[사용자 결정]`, `[실행 경로 선택]`을 제시한다. 다음 항목이 미확정이면 `BLOCKING`으로 표시하고 최종 SQL 또는 migration code 생성 전에 확인받는다.

- 어떤 branch/release와 schema version이 TO-BE 기준인지;
- 여러 create/update 경로 중 실제 migration 기준 로직;
- listener/event/outbox/cache/search-index side effect 실행 여부;
- ID 재사용 또는 재발급, relation 생성 순서, audit/history 값 정책;
- application-only converter, encryption, external lookup을 SQL로 대체할 수 있는지.

확정 후 [sql-generation.md](sql-generation.md)에 따라 pre-check, migration, 대사, 복구 SQL을 생성하거나 Java/Spring batch 경로를 설계한다.
