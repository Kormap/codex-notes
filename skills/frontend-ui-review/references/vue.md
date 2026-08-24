# Vue 점검

## 컴포넌트와 상태

- 프로젝트가 사용하는 Vue 버전과 Options API 또는 Composition API 관례를 유지한다.
- props는 읽기 전용으로 다루고 변경 의도는 명시적인 emit 또는 기존 store action으로 전달한다.
- props와 state에서 계산할 수 있는 값은 `computed`를 우선하고, watcher는 외부 부수효과나 실제 비동기 동기화에만 사용한다.
- 목록 key는 항목의 안정적인 식별자를 사용한다. 삽입·삭제·재정렬되는 목록에서 index를 key로 사용하지 않는다.
- composable 추출은 상태 로직이 실제로 재사용되거나 컴포넌트 책임을 명확히 줄일 때만 한다.

## 비동기와 생명주기

- 검색·필터·페이지 전환처럼 요청이 겹칠 수 있으면 AbortController, request id 또는 프로젝트의 동등한 방식으로 오래된 응답을 무시한다.
- event listener, timer, subscription과 진행 중 요청은 적절한 lifecycle에서 정리한다.
- 제출 중 상태를 표시하고 중복 요청을 방지하며 실패 시 사용자가 재시도하거나 입력을 복구할 수 있게 한다.

## 템플릿과 보안

- 기본 interpolation escaping을 우회하지 않는다. `v-html`은 신뢰 경계와 sanitizer가 확인된 콘텐츠에만 사용한다.

## 성능과 검증

- 큰 route는 필요할 때 lazy loading하고, 화면에 수천 건을 렌더링할 가능성이 있으면 pagination 또는 virtualization을 검토한다.
- 불안정한 props, 깊은 watcher, 불필요한 reactive 대형 객체와 중복 API 호출을 확인한다.
- 기존 lint, type-check, unit/component test를 실행하고 주요 상태 전환을 실제 브라우저에서 확인한다.
