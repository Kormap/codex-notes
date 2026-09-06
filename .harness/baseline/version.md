# Baseline Version

- Version: `0.4.0-context-routing`
- Status: 활성
- Effective date (Asia/Seoul): 2026-09-06
- Approved by: repository owner

## 버전 의미

`0.4.0-context-routing`은 `tr-20260906-context-refactor-promotion-01`을 근거로 공통 지침을 압축하고 상세 운영 계약을 조건부 skill과 Harness 문서로 라우팅한다. 프로젝트 override로 전역·저장소의 같은 원본 중복 주입을 제거하고, Windows 복사 설치의 중앙 Harness 경로 기록을 보완한다.

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
| `0.3.0-reference-lifecycle` | 2026-09-03 | 이전 | trace 정리 후에도 durable 산출물이 유효하도록 보관 경계를 정리하고 report signal·candidate trace·baseline version 참조 및 승격 lifecycle 검증 추가 |
| `0.4.0-context-routing` | 2026-09-06 | 활성 | `tr-20260906-context-refactor-promotion-01`을 근거로 승인된 candidate를 승격해 공통 context를 축소하고 조건부 계약 라우팅, 프로젝트 중복 방지와 Windows 최초 복사 설치를 보완 |
