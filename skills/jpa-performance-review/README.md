# jpa-performance-review

JPA Entity, Repository, JPQL과 QueryDSL의 쿼리 수, fetch 전략, 영속성 컨텍스트 비용과 bulk 처리 위험을 분석하는 스킬이다.

## 주요 산출물

- N+1과 실제 쿼리 발생 경로 분석
- fetch join, `EntityGraph`, batch size, DTO projection 선택안
- 페이징·정렬·집계와 bulk update/delete 위험
- OSIV와 transaction 범위 점검
- repository/query 개선 예시와 검증 방법

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
