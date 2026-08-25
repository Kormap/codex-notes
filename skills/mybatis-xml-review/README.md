# mybatis-xml-review

MyBatis mapper XML, interface와 DTO/VO 매핑을 함께 확인해 동적 SQL 오류, injection, N+1과 페이징·count 비용을 리뷰하는 스킬이다.

## 주요 산출물

- parameter, null 분기와 `resultMap` 정합성 점검
- `${}` injection과 잘못된 dynamic SQL 분석
- `IN` list, count query, OFFSET paging 성능 검토
- 수정된 mapper XML 예시
- DB 문법 가정과 필요한 테스트

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
