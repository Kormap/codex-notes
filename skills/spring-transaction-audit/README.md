# spring-transaction-audit

Java/Spring 서비스의 transaction 경계, rollback, connection 점유, lock과 동시성 정합성을 점검하는 스킬이다.

## 주요 산출물

- Controller→Service→Repository→외부 시스템 transaction 흐름
- rollback·proxy·event 처리 문제
- race condition, lock 범위와 deadlock 위험
- 외부 호출과 DB connection 점유 개선안
- 필요한 코드 예시와 검증 방법

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
