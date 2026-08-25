# logging-observability

Java/Spring 요청, 비동기 작업, batch와 외부 호출의 추적성을 높이면서 secret과 개인정보 노출을 방지하는 스킬이다.

## 주요 산출물

- traceId/MDC 전달과 request·async boundary 점검
- 상황별 적절한 log level과 structured context
- 민감정보 마스킹 및 금지 항목
- counter, timer, latency, lag 등 metric 제안
- 필요한 filter/interceptor 또는 logging 코드 변경

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
