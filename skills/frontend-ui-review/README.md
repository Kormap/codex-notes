# frontend-ui-review

JSP/JSTL, Vue, React, CSS 화면을 구현하거나 리뷰하면서 상태 정합성, XSS, 반응형 UI, 비동기 동작과 시각 회귀를 점검하는 스킬이다.

## 기술별 지침

| 작업 대상 | 참고 지침 |
|---|---|
| JSP/JSTL | [references/jsp.md](references/jsp.md) |
| Vue | [references/vue.md](references/vue.md) |
| React | [references/react.md](references/react.md) |
| CSS 또는 화면 품질 | [references/css-ui.md](references/css-ui.md) |

여러 기술이 섞인 화면은 실제 변경 대상에 해당하는 문서만 조합한다.

## 주요 산출물

- 구현 요청: 필요한 코드 변경, lint/type-check/test 결과와 실제 브라우저 검증 범위
- 리뷰 요청: 심각도순 발견 사항, 사용자 영향, 파일·라인과 수정 방향
- 공통: loading, empty, error, validation, disabled 상태와 desktop/mobile 확인 결과

실행 지침은 [SKILL.md](SKILL.md)를 확인한다.
