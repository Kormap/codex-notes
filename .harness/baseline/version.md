# Baseline Version

- Version: `0.3.0-reference-lifecycle`
- Status: 활성
- Effective date (Asia/Seoul): 2026-09-03
- Approved by: repository owner

## 버전 의미

`0.3.0-reference-lifecycle`은 원본 trace 보관과 durable report 검증의 경계를 분리하고, candidate 비교 trace·report signal·baseline version 참조 검증 및 `PROMOTED` lifecycle을 포함한다. `0.2.0-report-source-integrity`로 승격된 candidate의 완료 상태와 승격 메타데이터도 구조화한다.

## 변경 규칙

- 오탈자, 링크 수정처럼 의미가 바뀌지 않는 변경은 patch 수준으로 기록한다.
- 실행·검증 계약이나 용어 의미를 보완하면 minor 수준으로 기록한다.
- 기존 작업 흐름과 호환되지 않는 기준 변경은 major 수준으로 기록한다.
- 초기 버전 이후 의미 변경은 관련 trace 또는 report와 candidate의 검증 근거를 남긴 뒤 baseline에 반영한다.
- 버전을 변경할 때 적용일과 변경 요약을 이 문서에 함께 기록한다.

## 변경 이력

| 버전 | 적용일 (`Asia/Seoul`) | 상태 | 변경 요약 |
|---|---|---|---|
| `0.1.0-initial` | 2026-09-02 | 초기 적용 | Harness 적용 범위, 모든 Harness 작업의 최소 trace, 조건별 역할·정책·확장 trace, 문서 경계와 핵심 용어 정의 |
| `0.2.0-report-source-integrity` | 2026-09-03 | 이전 | `tr-20260903-report-source-promotion-01`을 근거로 승인된 candidate를 승격해 report source 행과 원본 trace의 필수 집계 필드를 대조하고 불일치를 오류로 차단 |
| `0.3.0-reference-lifecycle` | 2026-09-03 | 활성 | trace 정리 후에도 durable 산출물이 유효하도록 보관 경계를 정리하고 report signal·candidate trace·baseline version 참조 및 승격 lifecycle 검증 추가 |
