# dev-harness

비단순 개발 작업에서 필요한 task, evaluator, trace와 조건부 정책만 선택적으로 읽도록 연결하는 Harness 라우터 skill이다.

## 적용 대상

- 비단순 구현·리팩터링·설정, 버그 수정과 동작 변경
- 재현 가능한 평가가 필요한 작업
- 고위험, 반복 품질 평가 또는 멀티·서브에이전트 작업

고위험·반복 품질 평가·멀티에이전트는 한 줄 수정이어도 적용한다. 그 외 낮은 위험의 한 줄 수정, 문법 질문과 짧은 읽기 전용 확인에는 적용하지 않는다. 읽기 전용 작업의 trace는 사용자가 기록을 요청하거나 승인한 경우에만 생성한다.

중앙 Harness 위치는 [resolve-root.sh](scripts/resolve-root.sh)로 확인한다. Windows 일반 디렉터리 설치에서는 저장소의 `scripts/setup.sh`가 기록한 사용자 경로를 사용한다. 복합 작업은 주 task 외의 필요한 evaluator도 적용한다.

실행 지침과 선택 규칙은 [SKILL.md](SKILL.md)를 확인한다.
