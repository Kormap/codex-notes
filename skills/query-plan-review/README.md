# query-plan-review

SQL, DDL과 실행계획을 기반으로 join cardinality, scan, sort, paging과 index 비용을 분석하는 스킬이다.

## 주요 산출물

- 실행계획 병목과 예상 비용
- 1,000만 row 및 트래픽 증가 시 위험
- query rewrite 제안
- column 순서 근거를 포함한 index DDL
- write overhead, lock과 index bloat trade-off

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
