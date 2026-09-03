# Query Performance Evaluator

## 메타데이터

- `schema_version`: `1`
- `evaluator_id`: `query-performance`
- `task_id`: `query-performance`

## 사전 조건

- [query-performance task](../tasks/query-performance.md)의 기준 SQL, DBMS/version, representative bind와 데이터 규모가 확인되어 있다.
- 기준과 변경 실행계획은 동일한 schema·통계·bind 조건에서 비교한다. 조건이 다르면 차이를 명시하고 측정값을 직접 비교하지 않는다.
- 운영·스테이징에서의 `EXPLAIN ANALYZE`, DDL 또는 부하 테스트는 읽기·쓰기 영향과 승인 경계를 먼저 확인한다.

## 검사 (`evaluation_checks`)

| 검사 (`check_id`) | 연결 성공 조건 (`acceptance_criteria`) | 필수 여부 (`requirement`) | 방법 (`method`) |
|---|---|---|---|
| `EV-QPERF-01` | `AC-QPERF-01` | `REQUIRED` | 기준 plan·metric에서 scan, join, sort, estimated/actual rows와 반복 실행 비용 식별 |
| `EV-QPERF-02` | `AC-QPERF-02` | `REQUIRED` | 동일 조건의 변경 plan·metric을 기준과 비교하고 병목 이동 확인 |
| `EV-QPERF-03` | `AC-QPERF-03` | `REQUIRED` | 대표·경계 bind의 결과 집합, 순서, pagination, null과 lock 의미 비교 |
| `EV-QPERF-04` | `AC-QPERF-04` | `CONDITIONAL` | index·DDL 변경 시 write amplification, storage, lock, 배포·rollback 검토 |
| `EV-QPERF-05` | `AC-QPERF-05` | `REQUIRED` | cardinality와 호출 빈도로 1,000만 row·10배 트래픽 병목 및 관측 지표 검토 |
| `EV-QPERF-06` | `AC-QPERF-06` | `REQUIRED` | 실제 검증 범위와 성능 주장, trace·사용자 보고의 한계 대조 |

## 검사별 판정

### `EV-QPERF-01` 기준 병목

- `PASS`: 기준 plan 또는 측정값이 대표 조건과 함께 있고 주요 비용과 row 추정 오차가 설명된다.
- `FAIL`: 병목 설명이 plan·metric과 모순되거나 핵심 비용을 누락한다.
- `BLOCKED`: plan·metric 또는 이를 생성할 안전한 환경이 없어 병목을 신뢰성 있게 판정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-QPERF-02` 변경 효과

- `PASS`: 동일 조건의 변경 plan·metric에서 목표 병목이 줄고 새 지배적 병목이 설명된다. 제공된 plan만 분석한 경우에는 plan상 개선으로 한정해 표현한다.
- `FAIL`: 비용이 악화되거나 개선 주장이 비교 근거와 모순된다.
- `BLOCKED`: 기준과 변경 조건을 맞출 수 없어 효과를 비교할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-QPERF-03` 결과 정합성

- `PASS`: 대표·경계 조건에서 결과 값과 순서, pagination·null·lock 의미가 동일하다.
- `FAIL`: 누락·중복 row, 순서 변화, 잘못된 null 처리 또는 동시성 의미 변화가 있다.
- `BLOCKED`: 비교 데이터·fixture 또는 실행 환경이 없어 의미 보존을 판정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-QPERF-04` DDL 운영 영향

- `PASS`: 변경 DDL의 write·storage·lock 영향과 적용·rollback 절차가 확인되었다.
- `FAIL`: index 중복, 과도한 write 비용, 위험한 lock 또는 복구 불가능한 적용안이 남아 있다.
- `BLOCKED`: 운영 조건이나 기존 index 정보를 확인할 수 없어 안전성을 판정할 수 없다.
- `NOT_APPLICABLE`: index·DDL을 추가하거나 변경하지 않을 때만 허용한다.

### `EV-QPERF-05` 규모와 관측성

- `PASS`: 1,000만 row·10배 호출에서의 비용 증가 경로, 한계와 확인할 metric이 구체적이다.
- `FAIL`: 데이터 증가 시 지배적 비용 또는 운영 관측 방법을 누락한다.
- `BLOCKED`: cardinality와 호출 빈도의 합리적인 범위조차 정할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

### `EV-QPERF-06` 주장과 보고 정합성

- `PASS`: 측정된 개선, plan상 추정과 미검증 성능을 구분하고 trace·사용자 보고가 일치한다.
- `FAIL`: 실행하지 않은 benchmark를 측정 결과처럼 표현하거나 미검증 정합성·운영 위험을 누락한다.
- `BLOCKED`: 최종 trace 또는 사용자 보고 초안이 없어 대조할 수 없다.
- `NOT_APPLICABLE`: 허용하지 않는다.

## 전체 판정

- `PASS`: 모든 `REQUIRED` 검사와 적용되는 `CONDITIONAL` 검사가 `PASS`다. 실제 DB 실행 없이 제공된 두 plan을 비교한 경우 `PASS`는 plan 분석 계약 충족을 뜻하며 실측 latency 개선을 뜻하지 않는다.
- `FAIL`: 하나 이상의 검사가 `FAIL`이다.
- `BLOCKED`: `FAIL`은 없지만 하나 이상의 필수 검사가 `BLOCKED`다.

## Trace 반환

DBMS/version, 비교 조건, plan 또는 명령의 비민감 식별자, 핵심 node·row·latency 변화와 정합성 결과를 기록한다. SQL 원문이나 운영 데이터가 민감하면 마스킹하고 재현에 필요한 schema와 집계 근거만 남긴다.
