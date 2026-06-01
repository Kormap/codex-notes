---
name: deploy-checklist
description: Build or review production deployment checklists for backend services, DB migrations, configuration changes, feature flags, rollback plans, health checks, and monitoring. Use when Codex is asked to prepare a release, review deployment risk, inspect CI/CD changes, or plan safe rollout for Java/Spring applications.
---

# Deploy Checklist

## Workflow

1. Identify release scope: code, DB, config, infra, scheduled jobs, external integrations.
2. Separate pre-deploy, deploy, post-deploy, and rollback steps.
3. Check backward compatibility and order of operations.
4. Define health checks, smoke tests, metrics, logs, and alert thresholds.
5. Make rollback concrete and time-bounded.

## Checklist

- DB migration is backward compatible with the currently running app.
- Large DDL avoids long locks or has a maintenance/online migration plan.
- Config and secrets exist in every target environment.
- Feature flags default to safe behavior.
- Batch jobs and schedulers are paused/resumed intentionally.
- Health check validates dependencies only where appropriate.
- Rollback handles DB schema/data compatibility.
- Post-deploy smoke test covers the changed API or workflow.

## Output

- Use sections: `[사전 점검]`, `[배포 순서]`, `[검증]`, `[롤백]`, `[모니터링]`.
- Include commands only when they are project-specific and safe.
- Call out blockers separately from recommendations.
