---
name: mybatis-xml-review
description: Review MyBatis mapper XML, dynamic SQL, resultMap mappings, pagination queries, count queries, parameter binding, and SQL performance. Use when Codex is asked to inspect MyBatis XML files, mapper interfaces, DTO mappings, Oracle/MySQL/PostgreSQL SQL fragments, or legacy Spring MVC persistence code.
---

# MyBatis XML Review

## Workflow

1. Read mapper XML, mapper interface, DTO/VO, and calling service together.
2. Verify parameter names, null handling, dynamic SQL branches, and result mappings.
3. Check generated SQL shape for worst-case filters.
4. Review count query, paging query, and sort options separately.
5. Propose XML changes that preserve existing mapper style.

## Checklist

- `${}` injection risk; prefer `#{}` except validated identifiers such as whitelisted sort columns.
- `<if>` branches that generate invalid SQL or drop selective predicates.
- `<foreach>` with huge `IN` lists; consider temp table, join table, or chunking.
- `resultMap` mismatch, missing nested mapping, or accidental N+1 select.
- Duplicate SQL fragments that can drift.
- OFFSET paging on large tables.
- Count query doing unnecessary joins/order/group work.

## Output

- Use sections: `[매핑]`, `[동적 SQL]`, `[성능]`, `[개선안]`, `[테스트]`.
- Include corrected XML snippets when useful.
- Mention DB-specific syntax assumptions.
