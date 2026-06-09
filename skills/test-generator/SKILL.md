---
name: test-generator
description: JUnit, Mockito, Spring MVC, 통합 테스트로 회귀, 경계값, 동시성, 실패 경로 테스트를 추가하거나 보강할 때 사용한다.
---

# 테스트 생성

## 작업 흐름

1. 프로젝트의 테스트 스택을 확인한다: JUnit 버전, Mockito, AssertJ, Spring Boot Test, MockMvc, Testcontainers.
2. 기존 테스트를 읽고 naming, fixture, assertion, package 구조를 맞춘다.
3. 테스트 작성 전 behavior contract와 failure mode를 먼저 정의한다.
4. 가장 작은 단위의 유용한 테스트부터 추가한다.
5. 가능한 가장 좁은 테스트 명령을 실행한다.

## 테스트 선택 기준

- Service logic: persistence 동작이 핵심이 아니면 mocked port/repository 기반 unit test.
- Controller/API: status, validation, response body, error format은 MockMvc/WebTestClient.
- Repository/query: SQL/JPA/MyBatis 동작이 리스크이면 slice 또는 integration test.
- Transaction/concurrency: rollback, locking, race condition이 중요하면 integration-style test.
- Regression: 먼저 버그를 재현하고, 그다음 수정 검증을 추가한다.

## 출력

- placeholder가 아닌 실제 테스트 파일을 작성한다.
- 리팩터링 비용을 키우는 내부 구현 상세 검증은 피한다.
- null/empty, 중복 요청, 권한, invalid state, 경계 날짜를 포함한다.
- 실행한 테스트 명령과 결과를 보고한다.
