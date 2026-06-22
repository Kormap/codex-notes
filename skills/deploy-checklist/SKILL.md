---
name: deploy-checklist
description: Java/Spring 배포 체크리스트, DB 마이그레이션, 설정 누락, feature flag, graceful shutdown, 롤백, 헬스체크, 롤아웃 모니터링 점검이 필요할 때 사용한다.
---

# 배포 체크리스트

## 작업 흐름

1. release 범위를 식별한다: code, DB, config, infra, scheduler, external integration.
2. pre-deploy, deploy, post-deploy, rollback 단계를 분리한다.
3. backward compatibility와 작업 순서를 확인한다.
4. health check, smoke test, metric, log, alert threshold를 정의한다.
5. rollback 절차를 구체적이고 시간 제한이 있는 형태로 만든다.

## 체크리스트

- DB migration이 현재 실행 중인 app과 backward compatible한지 확인한다.
- 대형 DDL은 긴 lock을 피하거나 maintenance/online migration 계획을 둔다.
- 모든 target environment에 config와 secret이 있는지 확인한다.
- feature flag 기본값은 안전한 동작이어야 한다.
- batch job과 scheduler는 의도적으로 pause/resume한다.
- shutdown hook, readiness, connection drain이 실제 배포 방식과 맞물려 무중단으로 동작하는지 확인한다.
- queue consumer나 scheduler worker는 중복 처리 없이 drain/pause/resume 순서를 지킬 수 있어야 한다.
- health check는 필요한 dependency만 검증한다.
- rollback이 DB schema/data compatibility를 감당하는지 확인한다.
- post-deploy smoke test는 변경된 API 또는 workflow를 포함한다.
- rollout 중 error rate, latency, consumer lag, 핵심 비즈니스 metric을 함께 관찰한다.

## 출력

- `[사전 점검]`, `[배포 순서]`, `[검증]`, `[롤백]`, `[모니터링]` 섹션을 사용한다.
- command는 프로젝트에 맞고 안전할 때만 포함한다.
- blocker와 recommendation을 분리해서 표시한다.
