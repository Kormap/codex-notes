# 마이그레이션 계약 템플릿

AS-IS와 TO-BE schema를 확보한 뒤 이 참고 문서를 읽는다. 초안 설계에서는 미확정 항목을 assumption/TBD로 기록할 수 있다. production 구현·실행 전에는 결과와 안전성을 바꾸는 계약 항목을 완료한다.

## 1. 범위와 컷오버

| 항목 | 결정 |
| --- | --- |
| Source systems | 하나 이상, source별 name·owner·접속 범위 기재 |
| Target systems | 하나 이상, target별 name·owner·쓰기 범위 기재 |
| Entity와 보존 기간 | |
| 실행 수명 | one-time full load / backfill / incremental catch-up / continuous CDC |
| 가용성·전환 | offline freeze / online snapshot+catch-up / phased / no-cutover |
| 변경 전달 | source query watermark / log-based CDC / application dual-write |
| 쓰기 소유권 | source-only / target-only / single-writer 전환 / dual-writer |
| Migration window와 downtime 예산 | |
| Data freeze 규칙 | |
| 담당자와 승인 권한자 | |

## 2. Entity와 field 매핑

target field에 기여하는 source field마다 한 행을 사용한다. source별 규칙이 다르면 별도 행으로 작성한다. 단일 source 이전이면 해당 source만 작성한다.

DDL 기반 SQL 생성이 필요하면 [sql-generation.md](sql-generation.md)를 읽고 DBMS/version, constraint/index/trigger/sequence, row 수와 실행 방식을 함께 확인한다.
field 분류, profiling SQL, 사용자 확인 질문과 진행 gate는 [field-confirmation.md](field-confirmation.md)를 따른다.

| Target system | Target table.column | Source system | Source table.column | Transform/default | Evidence | Mapping state | Gate | Decision ID | Validation query |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | `<source-name>` | | | | `UNRESOLVED` | `BLOCKING` / `NON_BLOCKING` | | |

`Mapping state`는 `CONFIRMED`, `DERIVED`, `DEFAULTED`, `NOT_APPLICABLE`, `UNRESOLVED` 중 하나만 사용한다. `DERIVED`와 `DEFAULTED`도 근거와 사용자 승인이 필요한 중요 규칙이면 확정 전까지 `UNRESOLVED`로 둔다.

### 사용자 결정 기록

| Decision ID | Target field 또는 범위 | 확인 질문 | 선택지와 영향 | 영향 row 수 | 권고안과 근거 | 사용자 결정 | 결정자·일시 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DM-001` | | | | | | | | `OPEN` / `DECIDED` |

권고안은 근거가 있을 때만 제시하며 자동 승인으로 간주하지 않는다. 결정이 바뀌면 기존 기록을 덮어쓰지 말고 mapping version과 변경 사유를 남긴다.

TO-BE 프로젝트 코드가 있으면 [tobe-project-mapping.md](tobe-project-mapping.md)를 읽고 각 mapping의 file:symbol 근거와 direct SQL 우회 로직을 별도 근거표에 기록한다.

다음은 반드시 명시한다.

- canonical identifier 생성과 필요 시 source-to-target cross-reference key;
- 같은 업무 entity가 둘 이상의 source에 있을 때 duplicate/conflict 우선순위;
- status, code, date/time-zone, currency/precision, character-encoding 변환;
- 이력/삭제/유효하지 않은 레코드와 개인정보·민감 컬럼;
- 매칭되지 않는 foreign key와 변환할 수 없는 레코드.

필수 field가 `UNRESOLVED`이거나 관련 decision이 `OPEN`이면 해당 범위의 최종 SQL과 target write는 차단한다. 확인된 subset만 진행할 때는 제외 field/entity와 후속 처리 방침을 별도로 승인받는다.

## 3. Source consistency와 변경 전달

mutable source, online backfill, incremental 또는 CDC이면 [incremental-cdc.md](incremental-cdc.md)를 읽고 source별로 작성한다.

| Source | Snapshot/consistency identifier | Low/high watermark 또는 CDC position | Update/delete/tombstone | Late arrival·overlap/replay | Schema change |
| --- | --- | --- | --- | --- | --- |
| `<source-name>` | | | | | |

## 4. 실행 설계

| 단계 | Input 경계 | Output/checkpoint | Idempotency 방식 | Transaction 경계 | 실패 처리 |
| --- | --- | --- | --- | --- | --- |
| Extract | | | | | |
| Transform/load | | | | | |
| Relationship repair | | | | | |
| Reconciliation | | | | | |

scheduler 기반 실행이면 [spring-scheduler-migration.md](spring-scheduler-migration.md)의 job-state와 제어 설계도 작성한다.

checkpoint마다 last committed/next unprocessed, inclusive/exclusive 경계, partition, 고정 upper bound, migration/mapping version, reject 발생 시 전진 여부, 수정된 reject의 redrive 경로를 정의한다.

## 5. Acceptance criteria와 대사

| 검증 항목 | Partition | Source 결과 | TO-BE 결과 | 허용 오차 | 근거/담당자 |
| --- | --- | --- | --- | --- | --- |
| Expected cardinality | mapping rule + entity | | | 승인된 규칙과 일치 | |
| Missing/extra/changed key | 동일 input boundary | | | 승인 없이는 0 | |
| Aggregate total | status/date partition | | | | |
| Referential integrity | entity 관계 | | | 0 violations | |
| Rejected rows | reason code | | | 명시적 처리 방침 | |
| Rerun | 동일 고정 input boundary | | | duplicate 또는 역행 없음 | |
| CDC readiness | lag/backlog + unresolved event | | | 승인된 lag 이하, unresolved 0 | |

허용 오차가 0이 아니면 값, 근거, 승인자를 기록한다.

## 6. 컷오버와 복구

| 단계 | 담당자 | Go/no-go 근거 | Monitoring query 또는 metric | Rollback/stop 조치 |
| --- | --- | --- | --- | --- |
| Pre-cutover backup과 source freeze | | | | |
| 적재 실행 | | | | |
| 대사 | | | | |
| reads/writes 전환 | | | | |
| Post-cutover 관찰 | | | | |

완전한 역변환이 불가능하면 point of no return, restore/switchback, forward-recovery 절차를 별도로 기록한다.
