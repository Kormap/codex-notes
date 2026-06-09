---
name: jpa-performance-review
description: JPA Entity, Repository, JPQL, QueryDSL에서 N+1, fetch 전략, 영속성 컨텍스트 비용, bulk update, OSIV 같은 ORM 성능 이슈를 점검할 때 사용한다.
---

# JPA 성능 리뷰

## 작업 흐름

1. Entity 연관관계, fetch type, repository query, service 접근 패턴을 파악한다.
2. lazy association이 언제 접근되고 SQL이 몇 번 발생하는지 확인한다.
3. 페이징, 정렬, 집계, bulk update/delete, DTO projection 경로를 점검한다.
4. 트랜잭션 범위와 영속성 컨텍스트 크기를 확인한다.
5. 가장 리스크가 낮은 fetch/query 전략을 제안한다.

## 체크리스트

- lazy collection 또는 loop 안의 `@ManyToOne` 접근으로 인한 N+1.
- collection `fetch join` + 페이징 조합. 필요하면 2-step query, batch size, DTO projection을 검토한다.
- eager fetch 남용. query별 fetch plan을 우선한다.
- 재사용성/쿼리 복잡도 기준으로 `@EntityGraph`와 fetch join을 선택한다.
- 큰 entity graph에 대한 dirty checking 비용.
- bulk update/delete 후 영속성 컨텍스트 stale 상태.
- OSIV가 service boundary 밖 lazy loading을 숨기는지.
- JPA가 생성하는 FK/조건절에 필요한 인덱스 누락.

## 출력

- `[쿼리 수]`, `[영속성 컨텍스트]`, `[fetch 전략]`, `[개선안]`, `[검증]` 섹션을 사용한다.
- 가능하면 repository/query 예시를 포함한다.
- SQL logging이나 Hibernate statistics는 검증 보조 수단으로만 제안하고, 운영 상시 설정으로 두지 않는다.
