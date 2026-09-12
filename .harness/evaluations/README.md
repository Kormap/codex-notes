# Harness Evaluations

이 디렉터리는 candidate 생성 전에 baseline 증거를 재현하기 위한 통제 입력과 격리 실행 자산을 관리한다. 평가 자산은 활성 baseline이나 candidate 구현이 아니며, 연결된 current-request evaluator의 합격 기준을 변경하지 않는다.

## 평가 목록

- [execution-mode-routing](execution-mode-routing/README.md): 메인·멀티 실행 모드 라우팅의 다섯 통제 시나리오

## 경계

- fixture source와 검증 스크립트는 네트워크, 외부 계정, 운영 데이터에 의존하지 않는다.
- 실행 workspace는 새 임시 경로에 만들고 활성 저장소와 사용자 Skill·agent 설치를 수정하지 않는다.
- baseline과 candidate 비교에서 fixture commit, 모델, reasoning effort, sandbox, 출력 schema와 검증 명령을 동일하게 유지한다.
- 평가 결과는 기존 extended trace와 report 계약으로 기록하며 이 디렉터리에 원본 세션 로그를 보관하지 않는다.
