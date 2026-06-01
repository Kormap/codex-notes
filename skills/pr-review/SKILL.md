---
name: pr-review
description: Review pull requests and code diffs with a backend operations lens. Use when Codex is asked to review a GitHub PR, local git diff, branch comparison, or changed files for bugs, regressions, missing tests, transaction/concurrency risks, DB performance issues, deployment risk, or production-readiness.
---

# PR Review

## Workflow

1. Identify the review target: PR number, branch diff, staged diff, or changed files.
2. Read the changed files and the surrounding code that defines contracts, transactions, queries, and tests.
3. Prioritize findings by production impact, not style preference.
4. Check whether the change is covered by focused tests.
5. Report findings first. Keep summary secondary.

## Review Priorities

- Runtime bugs: null handling, wrong branch conditions, broken API contracts, serialization issues.
- Data correctness: lost updates, duplicate writes, stale reads, partial updates, missing idempotency.
- Transactions: overly wide `@Transactional`, external calls inside transactions, rollback mismatch.
- Concurrency: race conditions, lock ordering, deadlock risk, non-atomic read-modify-write.
- DB cost: N+1, unindexed filters, excessive count queries, OFFSET paging on large tables.
- Operations: logging gaps, missing metrics, rollback difficulty, risky migrations or config changes.
- Tests: missing failure cases, boundary cases, concurrency/data integrity cases.

## Output

- Start with findings ordered by severity.
- Include file and line references when available.
- For each finding, include impact and a concrete fix direction.
- If no issues are found, say so clearly and mention residual test or runtime risk.
- Avoid broad refactors unless directly required by the diff.
