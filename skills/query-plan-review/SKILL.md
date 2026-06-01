---
name: query-plan-review
description: Analyze SQL, execution plans, indexes, joins, paging, count queries, and slow query symptoms for Oracle, MySQL, or PostgreSQL. Use when Codex receives SQL text, EXPLAIN output, execution plan rows, table DDL, index definitions, query latency, or database performance questions.
---

# Query Plan Review

## Workflow

1. Identify DB engine, table sizes, predicates, joins, ordering, grouping, and paging.
2. Read the execution plan from the driving table outward.
3. Estimate row counts, filter selectivity, join cardinality, and repeated subquery cost.
4. Check whether existing indexes match equality, range, order, and covering needs.
5. Propose query rewrite and index DDL with tradeoffs.

## Checklist

- Full scan on large table.
- Index skipped due to function, implicit conversion, leading wildcard, column order, or low selectivity.
- Nested loop with large outer row count.
- Sort/hash/temp table caused by `ORDER BY`, `GROUP BY`, `DISTINCT`, or window functions.
- N+1 access pattern hidden behind application loops.
- Separate `count(*)` query cost in pagination.
- OFFSET pagination on large result sets; prefer cursor/keyset where possible.

## Output

- Use sections: `[문제 분석]`, `[비용 추정]`, `[개선안]`, `[스케일]`.
- Include DDL when recommending an index.
- Explain why column order is chosen.
- Mention write overhead and index bloat when adding indexes.
