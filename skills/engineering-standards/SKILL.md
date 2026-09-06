---
name: engineering-standards
description: Java/Spring·인프라·batch·legacy의 구현·설계·리뷰와 성능·장애 분석에 운영 기준을 적용한다. 문법·단순 개념 질문에는 사용하지 않는다.
---

# Engineering Standards

현재 작업에 해당하는 절만 적용한다. 응답 프로필은 분석 관점이며 별도 에이전트 생성 지시가 아니다. DB·Frontend 등 더 구체적인 skill은 해당 작업일 때만 읽는다.

## Java/Spring

- 기존 패키지 구조와 camelCase를 유지하고 과도한 checked exception을 피한다. 적절한 경우 custom runtime exception을 선호한다.
- SLF4J/Logback과 운영 진단에 필요한 로그 수준을 사용한다.
- 변경 경로의 transaction 범위·전파·rollback, 외부 호출 중 connection 점유, race condition·lock·deadlock을 점검한다.
- 대량 데이터 로딩과 안전하지 않은 Stream 사용, 계층 책임·의존 방향·예외 처리·로그를 확인한다.

## Infrastructure

- Docker·Kubernetes·EC2·Nginx·SSL·network·배포·CI/CD 변경은 요청 흐름과 병목 계층을 확인한다.
- SPOF, resource limit, health check와 graceful shutdown을 점검한다.
- cache, load balancing, horizontal scalability와 모니터링 지표·장애 대응을 검토한다. 배포가 범위이면 `deploy-checklist`도 적용한다.

## Batch와 Legacy

- 대용량 처리·scheduler·정산에서는 cursor/chunk 선택, 메모리·chunk 크기, chunk별 commit, 실패 후 재시작, 멱등성, 진행 추적과 table lock 위험을 설명한다.
- JSP/Spring MVC 혼합 구조와 Apache/Nginx·WAS 분리를 고려한다. 현재 환경에서 운영 가능한 점진적 개선을 우선한다.

## 성능·설계와 원인 불명 장애

- 성능, 장애 또는 구조 변경이 관련되면 200+ TPS, 동시 사용자 1,000명 이상, 단일 테이블 1,000만 row와 트래픽 10배에서의 병목을 판단한다. 단순 작업에는 이 전제를 강요하지 않는다.
- 원인이 불명확하면 infrastructure → DB → transaction → concurrency → code structure → implementation defect 순으로 조사한다. 명확한 코드 변경은 영향 코드부터 시작하고 근거가 있을 때만 범위를 넓힌다.
- 구현 전에 구조와 책임 경계를 확인하고, 적용 가능한 개선안을 제시할 때 필요한 코드·SQL·DDL을 함께 제공한다. 측정하지 않은 성능 향상을 확정하지 않는다.
