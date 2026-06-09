---
name: spring-transaction-audit
description: Java/Spring 서비스에서 `@Transactional`, 롤백, 락, 커넥션 점유, 외부 API 호출, 데이터 정합성 장애를 점검할 때 사용한다.
---

# Spring 트랜잭션 점검

## 작업 흐름

1. 요청 흐름을 그린다: Controller -> Service -> Repository -> 외부 시스템.
2. 정확한 트랜잭션 경계와 그 안의 DB/외부 호출을 표시한다.
3. 공유 mutable state와 동시 요청 경로를 찾는다.
4. checked exception, runtime exception, async 작업, event의 롤백 동작을 확인한다.
5. 운영상 안전해지는 가장 작은 변경을 제안한다.

## 체크리스트

- 외부 API, 파일 I/O, 메시징, 긴 CPU 작업은 DB 트랜잭션 밖으로 분리한다.
- 네트워크 대기 중 DB 커넥션을 점유하지 않게 한다.
- 동시 쓰기가 invariant를 깨는 경우에만 optimistic/pessimistic lock을 사용한다.
- 여러 코드 경로의 락 획득 순서를 일관되게 유지한다.
- 락 쿼리는 `findByIdForUpdate`처럼 명시적 repository 메서드를 선호한다.
- 같은 클래스 내부 호출로 Spring transaction proxy를 우회하지 않는지 확인한다.
- 조회 경로는 `readOnly = true` 또는 트랜잭션 생략 가능성을 확인한다.
- 트랜잭션 내부 event 발행은 롤백 후 부작용을 확인하고, 필요하면 after-commit hook을 사용한다.

## 출력

- `[트랜잭션]`, `[동시성]`, `[락]`, `[개선안]`, `[검증]` 섹션을 사용한다.
- 수정 방향이 명확하면 코드 변경 예시를 포함한다.
- 커넥션 풀, 락, DB 경합이 커질 수 있으면 트래픽 10배 상황의 영향을 언급한다.
