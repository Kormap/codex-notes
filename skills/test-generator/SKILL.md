---
name: test-generator
description: Generate or improve tests for Java, Spring Boot, REST APIs, repositories, services, and legacy code. Use when Codex is asked to add JUnit, Mockito, Spring MVC, integration, repository, regression, boundary, concurrency, or failure-path tests for changed code or missing coverage.
---

# Test Generator

## Workflow

1. Detect the test stack from the project: JUnit version, Mockito, AssertJ, Spring Boot Test, MockMvc, Testcontainers.
2. Read existing tests to match naming, fixtures, assertions, and package structure.
3. Identify behavior contracts and failure modes before writing tests.
4. Add the smallest useful tests first.
5. Run the narrowest test command available.

## Test Selection

- Service logic: unit tests with mocked ports/repositories unless persistence behavior matters.
- Controller/API: MockMvc/WebTestClient tests for status, validation, response body, and error format.
- Repository/query: slice or integration tests when SQL/JPA/MyBatis behavior is the risk.
- Transactions/concurrency: integration-style tests when rollback, locking, or race conditions matter.
- Regression: reproduce the bug first, then verify the fix.

## Output

- Include concrete test files, not placeholder test names.
- Avoid testing implementation details that make refactoring expensive.
- Include edge cases: null/empty, duplicate requests, authorization, invalid state, boundary dates.
- Report the exact test command and result.
