---
name: spring-transaction-audit
description: Audit Spring service code for transaction boundaries, propagation, rollback behavior, locking, connection usage, and concurrency risks. Use when Codex reviews Java/Spring service logic, `@Transactional` methods, repository calls, external API calls, distributed locks, or production incidents related to data consistency.
---

# Spring Transaction Audit

## Workflow

1. Map the request path: Controller -> Service -> Repository -> external systems.
2. Mark the exact transaction boundary and every DB/external call inside it.
3. Identify shared mutable state and concurrent request paths.
4. Check rollback behavior for checked exceptions, runtime exceptions, async work, and events.
5. Suggest the smallest change that makes the flow operationally safe.

## Checklist

- Keep external API calls, file I/O, messaging, and long CPU work outside DB transactions.
- Avoid holding DB connections while waiting on network calls.
- Use optimistic or pessimistic locking only where concurrent writes can violate invariants.
- Keep lock acquisition order consistent across code paths.
- Prefer explicit repository methods for lock queries, e.g. `findByIdForUpdate`.
- Watch for self-invocation that bypasses Spring transaction proxies.
- Check `readOnly = true` for read paths and transaction absence for simple cacheable reads.
- Ensure events published inside transactions are safe after rollback; prefer after-commit hooks when needed.

## Output

- Use sections: `[트랜잭션]`, `[동시성]`, `[락]`, `[개선안]`, `[검증]`.
- Include code changes when the fix is clear.
- Mention 10x traffic impact when connection pool, locks, or DB contention can amplify.
