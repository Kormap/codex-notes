---
name: logging-observability
description: Java/Spring API 로그, traceId, MDC, 메트릭, 알림, 장애 추적성을 점검하거나 개선할 때 사용한다.
---

# 로깅과 관측 가능성

## 작업 흐름

1. 반드시 진단 가능해야 하는 실패/업무 흐름을 식별한다.
2. request boundary, async boundary, batch boundary, 외부 호출을 추적한다.
3. 로그가 secret/PII를 노출하지 않으면서 충분한 context를 담는지 확인한다.
4. 모든 줄이 아니라 의사결정 지점에 structured log와 metric을 추가한다.
5. 고트래픽 상황의 log level과 log volume을 확인한다.

## 체크리스트

- request ID, 안전한 user/account key, domain ID, external system name, latency, result를 포함한다.
- async executor 경계에서는 필요하면 MDC/traceId propagation을 구성한다.
- 예상 가능한 validation 실패는 API 정책에 따라 debug/info 또는 무로그로 둔다.
- 예상치 못한 시스템 실패는 exception stack과 함께 error로 남긴다.
- secret, token, password, full payload, 주민식별정보, 큰 blob은 로그에 남기지 않는다.
- 외부 호출, retry, queue lag, batch progress, DB-heavy operation에는 counter/timer를 추가한다.

## 출력

- `[추적성]`, `[로그 레벨]`, `[민감정보]`, `[메트릭]`, `[개선안]` 섹션을 사용한다.
- MDC filter/interceptor 또는 logging 변경이 명확하면 code snippet을 포함한다.
- TPS 200+ 기준 log volume 리스크를 언급한다.
