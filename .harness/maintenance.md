# Harness 유지보수 계약

`.harness/`, `skills/dev-harness/` 또는 Diagnostics의 구조·실행·검증·우선순위를 변경하기 전에 읽는다. 파일 정리나 context 최적화라는 이유로 의미 변경을 단순 문구 수정으로 취급하지 않는다.

- Baseline 의미·용어·실행 계약 변경은 [context contract](baseline/context-contract.md), [version 변경 규칙](baseline/version.md)과 [candidate 계약](candidates/README.md)을 먼저 확인한다. 반복 실패에서 나온 변경뿐 아니라 모든 의미 변경에 적용한다.
- 초기 baseline은 저장소 소유자의 명시적 승인으로 설정한다. 이후 의미 변경은 trace 또는 report와 candidate의 검증 근거를 확보한 뒤 반영한다. 평가 후보는 현재 실행 기준이 아니며, 승인 전 baseline에 반영하지 않는다. 일회성 예외를 공통 기준으로 승격하거나 상위 지침을 약화하지 않는다.
- 후보 수정 요청이나 정적 검사 통과를 승격 승인으로 해석하지 않는다. 비교·승격 근거를 만들어내거나 승인 없이 활성 version·`PROMOTED` 상태를 변경하지 않는다. 실제 승격은 candidate 계약의 판정·승인·version·이력 요건을 모두 따른다.
- Task/evaluator 추가·이름 변경은 연결 문서와 해당 README 색인을 함께 갱신한다. Trace schema·template 변경은 [trace 계약](traces/README.md)을 읽고 호환성을 확인한다.
- Diagnostics·설치·참조 해석을 변경하면 `scripts/test-doctor-harness.sh`에 실제 정상·오류 경로의 fixture를 추가하거나 갱신한다. 문서 추가·이름 변경은 색인을 갱신하고, 검사 대상이나 구조 계약이 달라질 때만 doctor 코드도 수정한다.
- 변경 후 `./scripts/doctor.sh`와 `./scripts/test-doctor-harness.sh`를 실행한다. 문서 pairing·hook 변경은 `sh scripts/test-doc-sync.sh`도 실행한다. 필수 검사 실패·미실행을 통과로 보고하거나 검증 완료 상태로 승격하지 않는다.

문서 의미·작업별 라우팅은 script 통과와 별도로 검토한다. Report만 생성할 때는 [report 계약](reports/README.md)을 적용하며 candidate 문서는 생성·평가·승격이 실제 범위일 때 읽는다.
