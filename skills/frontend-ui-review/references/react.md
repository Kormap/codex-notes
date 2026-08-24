# React 점검

## 컴포넌트와 상태

- props나 기존 state에서 계산할 수 있는 값을 별도 state에 복제하지 않는다.
- state는 실제 소유 컴포넌트 가까이에 두고, 여러 소비자가 공유할 때만 기존 context나 store 관례를 따른다.
- Effect는 외부 시스템과의 동기화에 사용한다. 단순 파생 계산이나 사용자 이벤트 처리를 Effect로 옮기지 않는다.
- Hook dependency 경고를 무시하거나 비활성화해 stale closure를 숨기지 않는다.
- 목록 key는 안정적인 식별자를 사용하며 컴포넌트 상태 초기화 의도가 없으면 key를 임의로 변경하지 않는다.

## 비동기와 생명주기

- 요청이 겹칠 수 있는 흐름은 AbortController, request id 또는 데이터 계층의 동등한 기능으로 오래된 응답을 차단한다.
- Effect에서 listener, timer, subscription, 요청을 만들면 대응하는 cleanup을 제공한다.
- 제출 중 중복 실행을 막고 실패·재시도·optimistic update 원복을 사용자에게 명확히 보여준다.

## 렌더링과 보안

- `dangerouslySetInnerHTML`은 신뢰 경계와 sanitizer가 확인된 콘텐츠에만 사용한다.
- controlled/uncontrolled 입력 방식을 의도 없이 섞지 않고 설명과 validation error를 입력에 연결한다.

## 성능과 검증

- `memo`, `useMemo`, `useCallback`은 측정된 렌더링 문제나 안정적인 참조 계약이 있을 때 사용한다.
- 초기 bundle, 불필요한 상위 state 갱신, 대형 목록, 중복 fetch를 우선 점검한다.
- 기존 lint, type-check, unit/component test를 실행하고 주요 상태 전환을 실제 브라우저에서 확인한다.
