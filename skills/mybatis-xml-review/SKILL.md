---
name: mybatis-xml-review
description: Review MyBatis mapper XML, dynamic SQL, resultMap, pagination, count queries, parameter binding, and SQL performance. MyBatis XML, mapper interface, DTO mapping, Oracle/MySQL/PostgreSQL SQL fragment, legacy Spring MVC persistence 코드를 점검할 때 사용한다.
---

# MyBatis XML 리뷰

## 작업 흐름

1. mapper XML, mapper interface, DTO/VO, 호출 service를 함께 읽는다.
2. parameter 이름, null 처리, dynamic SQL 분기, result mapping을 확인한다.
3. 최악의 필터 조건에서 생성되는 SQL 형태를 확인한다.
4. count query, paging query, sort option을 별도로 리뷰한다.
5. 기존 mapper 스타일을 유지하는 XML 변경안을 제안한다.

## 체크리스트

- `${}` injection 위험. whitelist된 sort column 같은 검증된 식별자 외에는 `#{}`를 우선한다.
- `<if>` 분기가 잘못된 SQL을 만들거나 선택도 높은 조건을 빠뜨리는지 확인한다.
- 거대한 `IN` list를 만드는 `<foreach>`. temp table, join table, chunking을 검토한다.
- `resultMap` 불일치, nested mapping 누락, 의도치 않은 N+1 select.
- 중복 SQL fragment로 인한 drift 가능성.
- 대용량 테이블 OFFSET 페이징.
- count query가 불필요한 join/order/group 작업을 수행하는지.

## 출력

- `[매핑]`, `[동적 SQL]`, `[성능]`, `[개선안]`, `[테스트]` 섹션을 사용한다.
- 유용하면 수정된 XML snippet을 포함한다.
- DB별 문법 가정이 있으면 명시한다.
