---
name: logging-observability
description: Review and improve application logging, tracing, MDC, correlation IDs, metrics, alerts, and incident diagnosability. Use when Codex is asked to inspect logs, add logging, design observability for Java/Spring APIs, improve error visibility, or make production failures easier to trace.
---

# Logging Observability

## Workflow

1. Identify the failure or operation that must be diagnosable.
2. Trace request boundaries, async boundaries, batch boundaries, and external calls.
3. Check whether logs contain enough context without exposing secrets or PII.
4. Add structured logs and metrics at decision points, not every line.
5. Verify log level and volume under high traffic.

## Checklist

- Include request ID, user/account key when safe, domain ID, external system name, latency, and result.
- Use MDC/traceId propagation across async executors when applicable.
- Log expected validation failures at debug/info or not at all depending on API policy.
- Log unexpected system failures at error with exception stack.
- Avoid logging secrets, tokens, passwords, full payloads, resident identifiers, or large blobs.
- Add counters/timers for external calls, retries, queue lag, batch progress, and DB-heavy operations.

## Output

- Use sections: `[추적성]`, `[로그 레벨]`, `[민감정보]`, `[메트릭]`, `[개선안]`.
- Include code snippets for MDC filters/interceptors or logging changes when clear.
- Mention log volume risk at TPS 200+.
