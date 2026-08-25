# deploy-checklist

Java/Spring 애플리케이션 배포 전후의 DB, config, scheduler, 외부 연계와 rollback 준비 상태를 점검하는 스킬이다.

## 주요 산출물

- 사전 점검 항목과 blocker
- backward-compatible한 배포 순서
- health check와 smoke test
- rollback 절차와 제한 시간
- rollout monitoring metric과 alert 기준

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
