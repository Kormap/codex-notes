# Spring scheduler 마이그레이션 설계

`@Scheduled`, database job table, `Spring Batch` 등 Spring scheduling으로 마이그레이션을 구현할 때 이 참고 문서를 읽는다.

## 실행 모델 결정

| 필요 조건 | 권장 방식 |
| --- | --- |
| 작고 범위가 제한된 idempotent polling 작업 | 영속 run state와 distributed lock을 갖춘 `@Scheduled` service |
| 재시작 가능한 대용량 마이그레이션, skip/retry 정책, partitioning | scheduler가 실행하는 `Spring Batch` job |
| maintenance window의 일회성 컷오버 | 명시적으로 실행하는 job/runbook; 반복 cron에만 의존하지 않음 |

## 영속 run state

scheduler를 작성하기 전에 영속 run table 또는 동등한 model을 정의한다. migration 정의/version, source system, source partition/range, run status, owner, started/finished timestamp, checkpoint, attempt 수, processed/succeeded/rejected 건수, 마지막 실패 요약을 식별할 수 있어야 한다.

`PENDING → RUNNING → SUCCEEDED`, `RUNNING → RETRY_WAIT`, `RUNNING → FAILED`, `RUNNING → CANCELLED` 같은 상태 전이를 정의한다. 구현은 실행 가능한 작업만 원자적으로 claim해야 한다. stale `RUNNING` 레코드에는 명시적인 lease expiry와 복구 규칙이 필요하며, JVM crash가 이를 정리한다고 가정하지 않는다.

## Lock과 동시성 계약

- 마이그레이션별·source system별 허용 최대 동시 job 수를 정한다.
- replica 간에 동작하는 shared lock을 사용한다. audit 가능한 위치에 lock ownership/lease를 기록한다.
- schedule tick이 lock을 얻지 못하면 metric/log로 확인 가능한 skip으로 남긴다. 제한 없이 중복 실행을 queue에 쌓지 않는다.
- lock lease renewal과 renewal 실패 시 동작을 정의한다. 독점 소유권을 더 이상 보장할 수 없으면 쓰기를 계속하지 않는다.
- lease 기반 ownership에는 단조 증가 fencing token 또는 DB conditional version update를 사용해 stale worker의 commit을 storage 계층에서 거부한다.

## Chunk와 checkpoint 계약

chunk traversal에는 `(source_system, source_id)` 같은 immutable stable key를 사용한다. source 변경 포착에는 traversal key를 재사용하지 말고 [incremental-cdc.md](incremental-cdc.md)의 composite watermark 또는 CDC position 계약을 적용한다. 각 chunk의 transaction/durable acknowledgement 경계를 다음과 같이 정의한다.

1. 다음 source 범위 또는 작업 레코드를 claim한다.
2. item idempotency key와 unique/version constraint로 target 레코드를 변환·기록한다.
3. 처리 성공/반려 결과를 영속화하고 성공이 확인된 범위까지만 checkpoint를 전진시킨다.
4. Commit 또는 durable acknowledgement를 확인한다.

target write와 run-state가 동일 transactional resource이면 처리 결과와 checkpoint를 한 transaction으로 commit한다. 서로 다른 DB/API이면 분산 원자성을 가정하지 않는다. at-least-once 재전달을 전제로 target-side unique/version constraint, inbox/outbox 또는 durable acknowledgement를 사용하고 target 성공 확인 후 checkpoint를 전진시킨다. `target commit 성공 후 checkpoint 실패`는 안전한 재실행으로 흡수하고 `checkpoint 성공 후 target 미반영` 경로는 허용하지 않는다.

checkpoint는 last committed/next unprocessed, inclusive/exclusive 경계, partition과 고정 upper bound, migration version을 명시한다. reject를 건너뛰고 전진할 수 있다면 수정 후 다시 처리하는 redrive 경로와 완료 조건을 별도로 둔다. source 행이 변경될 수 있으면 offset pagination을 사용하지 않는다. 각 chunk는 별도의 transaction을 사용하며, 외부 호출은 transaction 밖에서 수행하거나 영속 request state로 idempotent하게 만든다.

`Spring Batch`를 사용하면 고정 `JobParameters`에 migration version과 input boundary를 포함하고, restart 가능한 `ItemReader`와 `ExecutionContext`를 사용한다. `JobRepository`가 cross-system exactly-once를 보장한다고 가정하지 않는다.

## 실패, retry, 운영

| 실패 분류 | 예시 | 필수 처리 |
| --- | --- | --- |
| Transient | 일시적인 DB/network dependency 장애 | 횟수 제한 retry와 backoff, checkpoint 유지 |
| Data/mapping | 유효하지 않은 source 값, 누락된 code mapping | source key와 사유로 반려, 승인된 정책에 따라서만 중지 또는 계속 |
| Integrity/conflict | duplicate business key, 깨진 관계 | 영향을 받은 범위를 중지하고 대사, 조용히 덮어쓰지 않음 |
| Infrastructure | lease 손실, shutdown, resource 고갈 | 현재 transaction 이후 안전하게 중지하고 run을 재개 가능하게 유지 |

run status, 활성 run 경과 시간, 마지막 성공 checkpoint, lag/backlog, throughput, reject 수, retry 수, lock 획득 skip을 노출한다. pause/resume/cancel의 권한 있는 command 또는 endpoint를 정의하고 access control을 적용한다. cron 시간과 source timestamp의 time-zone 규칙은 명시한다.

## Scheduler 마이그레이션 전용 리허설 검증

- 중복 scheduler invocation을 동시에 실행하고 정확히 하나의 worker만 범위를 소유함을 검증한다.
- lease 만료 후 stale worker가 깨어나도 fencing으로 target commit이 거부됨을 검증한다.
- chunk 사이에 process를 중지하고, 새 instance가 duplicate 또는 누락 행 없이 재개함을 검증한다.
- target commit 직후 checkpoint 기록을 실패시키고 재실행이 duplicate나 역행 없이 완료됨을 검증한다.
- transient failure를 재시도하고 retry 횟수 제한과 backoff가 동작함을 검증한다.
- data rejection을 강제로 발생시켜 source key, 사유, 가시성, 승인된 처리 방침을 검증한다.
- scheduled run이 계획된 cutover window와 겹치지 않고, 마이그레이션 완료 표시 후 실행되지 않음을 검증한다.
