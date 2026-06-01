---
name: query-plan-review
description: Analyze SQL, execution plans, indexes, joins, paging, count queries, and slow query symptoms for Oracle, MySQL, or PostgreSQL. SQL, EXPLAIN, 실행계획, DDL, 인덱스, 조회 지연, DB 성능 질문을 분석할 때 사용한다.
---

# 실행계획 리뷰

## 작업 흐름

1. DB 종류, 테이블 크기, 조건절, 조인, 정렬, 그룹핑, 페이징을 확인한다.
2. 실행계획은 driving table부터 바깥쪽으로 읽는다.
3. 예상 rows, 필터링 선택도, 조인 cardinality, 반복 서브쿼리 비용을 추정한다.
4. 기존 인덱스가 equality, range, order, covering 요구와 맞는지 확인한다.
5. 쿼리 리라이트와 인덱스 DDL을 tradeoff와 함께 제안한다.

## 체크리스트

- 대용량 테이블 Full Scan 여부.
- 함수, 암시적 형변환, 선행 와일드카드, 컬럼 순서, 낮은 선택도로 인덱스가 스킵되는지.
- outer row 수가 큰 Nested Loop 여부.
- `ORDER BY`, `GROUP BY`, `DISTINCT`, window function으로 인한 sort/hash/temp table 여부.
- 애플리케이션 loop 뒤에 숨어 있는 N+1 접근 패턴.
- 페이징의 별도 `count(*)` 비용.
- 대용량 결과의 OFFSET 페이징 여부. 가능하면 cursor/keyset을 우선 검토한다.

## 출력

- `[문제 분석]`, `[비용 추정]`, `[개선안]`, `[스케일]` 섹션을 사용한다.
- 인덱스를 추천하면 DDL을 포함한다.
- 인덱스 컬럼 순서 선택 이유를 설명한다.
- 인덱스 추가 시 write overhead와 index bloat도 언급한다.
