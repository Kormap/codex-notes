# JSP/JSTL 점검

## 구조

- 기존 JSP, tag file, include, Spring MVC model 관례를 따른다.
- scriptlet과 JSP 내부 비즈니스 로직을 새로 추가하지 않는다. 조건·반복은 JSTL로 표현하고 계산·권한 판단·데이터 조회는 서버 계층에 둔다.
- fragment를 재사용하되 include 관계와 변수 범위를 불명확하게 만드는 과도한 분리는 피한다.

## 출력과 보안

- `${value}`가 자동으로 HTML-safe하다고 가정하지 않는다. 일반 텍스트는 기본 escaping이 활성화된 `<c:out>` 등 프로젝트의 검증된 출력 방식을 사용한다.
- HTML 본문, 속성, URL, CSS, JavaScript는 서로 다른 출력 문맥이다. 서버 값을 inline script나 event attribute에 문자열 결합으로 삽입하지 않는다.
- 사용자 작성 HTML이 꼭 필요하면 기존 sanitizer와 허용 정책을 확인한다. escaping을 끄는 변경은 데이터의 신뢰 경계와 정제 위치가 확인된 경우에만 한다.
- CSRF token, 권한에 따른 노출, 민감값 마스킹은 프로젝트의 기존 보안 메커니즘을 사용한다. 화면에서 숨기는 것을 권한 통제로 간주하지 않는다.

## 화면 동작

- 고유한 `id`, 오류 메시지와 입력 필드의 연관, 서버 검증 오류의 재표시를 확인한다.
- JSP가 먼저 유효한 기본 화면을 제공하고 JavaScript enhancement 실패 시 핵심 정보가 사라지지 않는지 확인한다.
- 중복 제출을 막더라도 서버 측 멱등성이나 검증을 대체한다고 가정하지 않는다.

## 검증

- 렌더링된 HTML에서 escaping, 중복 ID, 잘못 중첩된 요소, 깨진 URL과 form action을 확인한다.
- 정상·검증 실패·권한 없음·빈 결과 상태를 확인하고 브라우저 console과 network 실패를 점검한다.
