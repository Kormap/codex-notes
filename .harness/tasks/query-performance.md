# Query Performance Task

## 메타데이터

- `schema_version`: `1`
- `task_id`: `query-performance`
- `task_type`: `behavior_change`
- `evaluator_id`: `query-performance`
- `default_trace_level`: `minimum`

## 적용 조건

- SQL, ORM 생성 쿼리, 인덱스, pagination, count 또는 실행계획의 비용을 분석하거나 개선한다.
- 성능 개선 주장을 실행계획, 계측 또는 데이터 분포 근거로 비교해야 한다.

## 제외 조건

- 데이터 이전·backfill·CDC나 운영 cutover가 핵심이면 데이터 마이그레이션 계약을 사용한다.
- 단순 SQL 문법 수정이고 성능 주장이 없으면 현재 요청 식별자를 task로 사용한다.

## 필수 입력

- 원본 SQL 또는 SQL을 생성하는 코드와 bind 조건
- DBMS와 가능한 경우 정확한 version
- 테이블 DDL, 기존 index, 대략적인 row 수와 주요 column 분포
- 실제 또는 대표 실행계획과 현재 latency·rows examined 등 기준값
- 결과 정합성, 정렬, pagination과 동시 쓰기 요구사항

실행계획이나 데이터 분포 없이 병목을 확정하지 않는다. 실제 DB 접근이 없으면 사용자가 제공한 계획·통계로 판정 가능한 범위와 한계를 분리한다.

## 범위

### 포함

- scan, join, sort, temporary, 반복 subquery와 cardinality 병목 분석
- query rewrite 또는 필요한 최소 index 변경안
- 결과 집합·정렬·동시성 의미 보존 검증
- 읽기 개선과 write cost, lock, storage, index bloat trade-off 평가

### 제외

- 승인되지 않은 운영·스테이징 DDL/DML 실행
- 근거 없는 optimizer hint, 인프라 증설 또는 전역 DB 설정 변경
- 성능 문제와 무관한 schema·repository 리팩터링

## 금지 행동

- 실제 또는 제공된 실행계획 없이 성능 향상을 확정적으로 주장하지 않는다.
- 결과 row, 정렬, null 처리, lock 의미를 바꿔 속도만 개선하지 않는다.
- `SELECT *`, 무제한 조회, 깊은 OFFSET 또는 count 비용을 숨긴 채 index만 추가하지 않는다.
- write overhead와 운영 배포·rollback 영향을 평가하지 않은 DDL을 실행하지 않는다.

## 성공 조건 (`acceptance_criteria`)

- [ ] `AC-QPERF-01`: 기준 SQL·조건·데이터 규모와 병목이 실행계획 또는 계측 근거로 설명된다.
- [ ] `AC-QPERF-02`: 변경안의 scan·join·sort·예상 row 접근이 기준 대비 어떻게 달라지는지 비교된다.
- [ ] `AC-QPERF-03`: 원본과 변경안의 결과 집합, 정렬, pagination과 lock 의미가 동일함을 검증한다.
- [ ] `AC-QPERF-04`: index 또는 query 변경의 write cost, storage, 배포와 rollback 영향을 기록한다.
- [ ] `AC-QPERF-05`: 1,000만 row와 10배 트래픽에서 남는 병목과 모니터링 지표를 제시한다.
- [ ] `AC-QPERF-06`: 실행하지 못한 DB 검증과 성능 주장의 한계가 trace와 사용자 보고에 일치한다.

## Evaluator 전달 계약

- `evaluation_target`: `기준 SQL·실행계획과 변경 SQL·DDL·코드 및 가능한 비교 실행 결과`
- `required_evidence`: `DBMS/version, representative binds, plan 또는 측정값, 정합성 검증, 운영 trade-off`
- `allowed_not_applicable`: `실제 DB 실행은 접근 환경이 없고 제공된 실행계획만 분석하는 요청에서 허용하되 측정 성능 향상은 PASS로 주장할 수 없음`
