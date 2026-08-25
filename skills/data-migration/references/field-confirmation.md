# Field 확인과 사용자 결정 gate

DDL, 실제 데이터 분포 또는 TO-BE 프로젝트 로직만으로 field 의미를 확정할 수 없을 때 이 문서를 읽는다. 목표는 질문 수를 늘리는 것이 아니라 잘못된 mapping을 실행 전에 차단하고, 사용자가 판단할 정보와 영향을 명확히 제공하는 것이다.

## Field 분류

각 target field에 세 축을 기록한다.

| 축 | 값 | 의미 |
| --- | --- | --- |
| Mapping state | `CONFIRMED` | source와 변환 규칙이 근거 및 필요한 사용자 결정으로 확정됨 |
| Mapping state | `DERIVED` | 둘 이상의 값 또는 업무 규칙으로 결정적으로 계산되며 근거가 확정됨 |
| Mapping state | `DEFAULTED` | source 값 없이 적용할 default가 명시적으로 확정됨 |
| Mapping state | `NOT_APPLICABLE` | 이전 대상에서 제외되며 제외 이유와 영향이 확정됨 |
| Mapping state | `UNRESOLVED` | source, 변환, default, 제외 여부 중 하나 이상이 미확정됨 |
| Decision | `NONE` / `USER_DECISION_REQUIRED` | 사용자의 업무·운영 결정 필요 여부 |
| Gate | `BLOCKING` / `NON_BLOCKING` | 미확정 상태가 해당 범위의 최종 생성·실행을 차단하는지 여부 |

`DERIVED`, `DEFAULTED`, `NOT_APPLICABLE`은 추정 상태가 아니다. 계산식, default 또는 제외 근거와 영향이 확인된 뒤에만 사용한다.

## `BLOCKING` 판정

다음 중 하나라도 해당하고 규칙이 미확정이면 `BLOCKING`으로 둔다.

- primary/business key, ID 생성·보존, duplicate 병합과 source 우선순위;
- required/`NOT NULL` field, foreign key, 관계 생성 순서와 orphan 처리;
- status/code와 상태 전이, delete/soft-delete, history 유효기간;
- 금액, 통화, 단위, scale/precision, 반올림과 overflow;
- 날짜, timestamp, time zone, cutoff와 최신값 판단 기준;
- tenant/owner, 권한·보안 field, 개인정보, hash/encryption/masking;
- audit/version field와 생성·수정 주체/시각;
- type 변환, 문자열 잘림, charset/collation처럼 값 손실 가능성이 있는 규칙;
- direct SQL이 우회하는 validation, listener, event/outbox, cache/index side effect;
- 결과 row 수, 업무 의미 또는 rollback 가능성을 바꾸는 다른 미결 사항.

표시용 설명, 사용되지 않는 nullable legacy field처럼 실제 데이터·업무 동작에 영향이 없다는 근거가 있는 항목만 `NON_BLOCKING`으로 둘 수 있다. `NON_BLOCKING` 사유도 기록한다.

## 질문 전 데이터 확인

접근 권한과 실행 환경이 허용하면 source에 쓰지 않는 profiling SQL을 먼저 만든다. 실제 identifier와 DBMS dialect를 사용하며, 다음 결과를 field mapping 근거에 연결한다.

- total/null/non-null/distinct count와 주요 code/status별 count;
- business key duplicate와 duplicate 유형별 count;
- foreign key 후보의 matched/orphan count;
- min/max, 문자열 길이 분포, precision/scale 초과와 변환 실패 count;
- 날짜 범위와 time zone 해석에 따른 경계값 count;
- 후보 source 또는 변환 규칙별 matched/unmatched/changed row count;
- default, 제외, 병합 또는 truncate 선택 시 영향받는 row count.

개인정보·민감값은 원문 sample 대신 count, 범위, 마스킹된 값 또는 승인된 비식별 결과만 사용한다. profiling 결과가 없으면 사실처럼 추정하지 말고 실행할 query와 필요한 결과를 사용자에게 요청한다.

## 사용자 확인 방식

관련 질문을 한 번에 묶되 서로 다른 결정을 하나의 질문으로 합치지 않는다. 각 질문에는 다음을 포함한다.

1. `Decision ID`와 대상 `table.column` 또는 entity
2. 왜 결정이 필요한지와 현재 근거
3. 가능한 선택지와 각 선택지가 데이터에 미치는 영향
4. 확인된 경우 영향 row 수와 대표적인 비민감 분포
5. 근거가 충분할 때만 권고안과 이유
6. 답변하지 않을 때 차단되는 SQL, entity 또는 실행 단계

사용자가 명시적으로 선택하기 전에는 권고안을 채택하지 않는다. 자유 형식 답변도 결정 내용, 결정자, 일시, mapping version에 기록하고 모순되거나 범위가 불명확하면 다시 확인한다.

## 진행 gate

- `BLOCKING` + `UNRESOLVED` 또는 `USER_DECISION_REQUIRED`인 field가 하나라도 있으면 영향 범위의 최종 migration SQL/code와 target write를 중단한다.
- 읽기 전용 inventory, profiling SQL, 후보 mapping, 질문 목록은 gate 이전에도 제공할 수 있다.
- 사용자가 확인된 subset만 진행하길 원하면 포함/exclude 범위, 관계·constraint 영향, 미확정 데이터의 보관 또는 후속 처리 방침을 승인받는다.
- 모든 blocking decision을 반영한 뒤 mapping table과 validation query를 갱신하고, 서로 모순되는 결정이 없는지 다시 확인한다.
- mapping 승인은 production 실행 승인이 아니다. 실제 DDL/DML, scheduler 활성화, source freeze와 cutover는 별도 실행 승인을 받는다.

## 결정 기록 템플릿

| Decision ID | Target field 또는 범위 | 현재 근거 | 질문 | 선택지와 영향 | 영향 row 수 | 권고안 | 사용자 결정 | 결정자·일시 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DM-001` | | | | | | | | | `OPEN` / `DECIDED` |

결정 변경 시 이전 결정을 삭제하지 않는다. mapping version, 변경 사유, 재생성해야 하는 SQL/code와 이미 처리된 데이터의 재검증·보정 범위를 함께 기록한다.
