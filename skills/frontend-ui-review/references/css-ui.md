# CSS와 화면 품질 점검

## CSS 구조

- 기존 design token, component primitive, reset, naming, scoped/module 관례를 먼저 사용한다.
- 전역 selector, 높은 specificity, `!important`, inline style을 새로 추가하기 전에 영향 범위가 더 작은 방법을 선택한다. 동적 계산값처럼 이유가 명확한 inline style은 허용한다.
- hover, focus-visible, active, disabled, loading, selected, error 상태를 일관되게 표현한다.
- stacking context, fixed/sticky 요소, overlay, 긴 문자열, 긴 번역문, 이미지 비율과 scroll container의 clipping을 확인한다.
- 프로젝트가 명시한 브라우저 범위를 따르고 지원 근거 없이 최신 CSS 기능이나 vendor workaround를 추가하지 않는다.

## 반응형과 시각 품질

- 특정 기기명이 아니라 콘텐츠가 깨지는 지점을 기준으로 기존 breakpoint를 사용한다.
- 작은 viewport와 큰 viewport에서 정보·기능 손실과 의도하지 않은 가로 스크롤이 없는지 확인한다.
- empty/loading 상태뿐 아니라 실제로 가장 조밀한 데이터 상태와 validation error가 열린 상태를 확인한다.
- 사용자 동작이나 상태 변화가 있는 화면은 초기 상태와 변경 후 상태를 각각 시각 점검한다.

## 검증 증거

- lint나 정적 분석만으로 시각 품질 통과를 주장하지 않는다.
- 실제 브라우저에서 desktop/mobile viewport, console, failed network를 확인한다.
