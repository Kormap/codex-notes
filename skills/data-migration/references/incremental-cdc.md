# Incremental·CDC 일관성 설계

mutable source를 online으로 읽거나 backfill 뒤 incremental/CDC로 따라잡을 때 이 문서를 읽는다. keyset pagination만으로는 실행 중 update, delete, late commit을 안전하게 포착할 수 없다.

## 일관성 기준

- 가능하면 database-consistent snapshot과 해당 snapshot의 log position(`LSN`, `SCN`, `GTID` 등)을 함께 고정한다.
- 초기 snapshot의 종료점과 CDC 시작 위치 사이에 gap이 없음을 증명한다. 중복 구간은 item idempotency로 흡수할 수 있지만 누락 구간은 허용하지 않는다.
- watermark 기반 추출은 `(watermark, stable tie-breaker)` 순서를 사용하고 각 run 시작 시 high watermark를 고정한다. mutable `updated_at` 하나만 checkpoint로 사용하지 않는다.
- late arrival를 허용하면 overlap/replay 구간, 중복 제거 방식, 허용 지연, 재처리 종료 조건을 명시한다.

## 변경 의미

- insert, update, delete/tombstone, source key 변경을 target에 어떻게 반영하는지 정의한다.
- event position 또는 source version을 보존하고 오래된 event가 최신 target 값을 역행시키지 않도록 version-aware conditional upsert를 적용한다.
- schema 변경과 code/status mapping version 변경 시 중단·호환·replay 기준을 정한다.
- source와 target이 동시에 변경될 수 있으면 entity별 system of record, conflict detection, single-writer 또는 dual-writer 규칙을 명시한다.
- application dual-write는 두 system에 대한 원자성을 가정하지 않는다. write 순서, 공통 idempotency/version, 한쪽 성공·한쪽 실패의 durable retry/repair, divergence 탐지·대사, cutover 종료 조건을 정의한다. 가능한 경우 authoritative write + outbox/CDC 전달을 비교안으로 제시한다.

## Checkpoint와 대사

- checkpoint에는 source partition, snapshot identifier, low/high position, inclusive/exclusive 경계, mapping version을 포함한다.
- 동일 snapshot/watermark/CDC position에서 missing/extra/changed key와 aggregate를 대사한다.
- cutover 전 lag/backlog가 승인된 임계값 이하고 unresolved event가 0건인지 확인한다.
- CDC connector restart, event duplicate, out-of-order delivery, tombstone, schema change를 리허설한다.
