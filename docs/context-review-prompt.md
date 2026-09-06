# Context 리팩터링 독립 재검토 프롬프트

아래 내용을 새 Codex 작업에 전달한다. 작성자의 자체 평가를 합격 근거로 사용하지 않는다.

```text
현재 저장소의 Codex 지침·Harness·skills 리팩터링을 독립 reviewer로 검증하라.
파일을 수정하지 말고, trace·report·candidate·리뷰 파일도 생성하지 마라.
기존 검증 스크립트의 격리된 임시 fixture 실행은 허용한다.
현재 working tree는 아직 승격되지 않은 후보이며 commit·push·승격하지 마라.

목표는 persistent context 절감과 기존 필수 행동·안전·검증 계약 보존을
동시에 달성했는지 확인하는 것이다. 기존 리뷰나 설계가 옳다고 가정하지 마라.

1. git status, staged/unstaged/untracked를 확인하고 git diff HEAD 및
   필요한 변경 전 파일을 읽어 전체 후보를 검토하라. 새 파일도 빠뜨리지 마라.
2. 전역 AGENTS, 프로젝트 AGENTS.override, skill 목록과 선택 후 읽는 본문을
   구분하라. 전역 설정이 있는 경우와 없는 clone에서 원본이 누락되거나
   중복 로딩되는지 확인하라. README 감소를 startup 절감으로 합산하지 마라.
3. 필수 규칙마다 기존 위치 → 현재 위치 → 읽는 조건 → 강제 장치를 대조하라.
   MUST-PERSIST / SHOULD-PERSIST / ON-DEMAND / DERIVABLE / REDUNDANT / DEAD로
   분류하고, 이동된 파일의 존재만으로 행동 보존을 인정하지 마라.
4. 다음 시나리오에서 최초 문서, 추가 문서, 필수 검증, 중단 조건,
   불필요한 읽기와 누락 가능성을 확인하라.
   - Java 결함 수정 및 동작 보존 리팩터링
   - API와 Vue 화면 동시 변경
   - 한 줄이지만 고위험인 변경
   - 정확히 맞는 대표 task가 없는 설정 또는 지침 수정
   - Nginx/인프라 변경, 대용량 batch, 원인 불명 장애
   - AGENTS와 한국어 번역 변경
   - Harness/Diagnostics/설치 스크립트 변경
   - 일반 trace 기록, 재시도, 비밀값 기록 사고
   - report만 집계하는 작업
   - baseline 의미·우선순위 변경과 candidate 평가·승격
   - symlink 및 Windows 일반 디렉터리 skill 설치
5. 특히 다음 계약을 확인하라.
   - 복합 작업의 추가 evaluator와 모든 필수 검사의 최종 판정
   - 고위험 조건이 단순 작업 예외보다 우선함
   - refactor 전후 검증, INFRA·backend·batch·legacy 기준의 실제 발견 경로
   - trace의 실행 중 기록, 동일 작업 재시도와 독립 표본의 구분,
     유출 시 공유·커밋 중단, 원본과 durable artifact의 보관 경계
   - 문서 pairing, 정상·오류 fixture 동시 갱신, 실패 시 완료·승격 제한
   - baseline 모든 의미 변경의 version·candidate 계약 적용
   - 후보 준비 요청과 실제 승격 승인 구분, 과거 근거 왜곡 금지
   - 복사 설치에서 resolver가 다른 프로젝트의 cwd나 잘못된 로컬 경로를
     중앙 Harness로 오인하지 않으며 기존 설치 기록을 무단 덮어쓰지 않음
6. 다음 명령을 실행하고 정확한 결과를 보고하라.
   git diff HEAD --check
   ./scripts/doctor.sh
   ./scripts/test-doctor-harness.sh
   sh scripts/test-doc-sync.sh
   환경상 실행할 수 없으면 사유를 명시하고 통과로 처리하지 마라.
   macOS의 Windows 모드 fixture와 실제 Windows 검증을 구분하라.
7. Script가 검사하는 구조·enum·연결과 LLM이 판단해야 하는 의미를 구분하라.
   테스트가 구현 문구만 되풀이하거나 검사 자체를 약화해 통과시키는지 확인하라.
   영어·한국어 의미 동기화는 단순 파일 pairing 통과와 별도로 검토하라.
8. Persistent token 규모·추가 절감 여지를 산정하되 tokenizer 실측인지
   문자 기반 추정인지 명시하라. 도구 schema·외부 skill 목록은 분리하라.
   중복 제거 → 파생 정보 제거 → 조건부 분리 → 설명 압축 순으로 평가하라.
9. Diff를 SAFE DELETE / SAFE MOVE / RISKY MOVE / SEMANTIC CHANGE /
   POSSIBLE REGRESSION으로 구분하라. 각 문제는 파일·라인, 실제 오동작 예시,
   심각도와 최소 수정 방향을 포함하라. 신규 문제와 기존 문제도 구분하라.

최종 판정은 PASS / PASS WITH MINOR FIXES / FAIL — REVISION REQUIRED 중 하나다.
Critical, Recommended, Optional, Context Efficiency, Fidelity,
Commit Decision 순서로 요약하고 Commit Decision은 YES / NO로 답하라.
합격을 전제하지 말고, 실제 문제가 없으면 개선점을 억지로 만들지 마라.
```
