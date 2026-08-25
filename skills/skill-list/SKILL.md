---
name: skill-list
description: /스킬, 스킬 목록, skill list, 현재 사용 가능한 Codex skill 확인, 공식 사용자 경로·저장소 개인 skill·시스템 skill 기준 목록의 차이 점검이 필요할 때 사용한다.
---

# 스킬 목록 확인

## 작업 흐름

1. 이 스킬이 호출되면 먼저 이 스킬 디렉터리의 `scripts/doctor.sh`를 실행한다. 실패해도 목록 확인은 계속하고 실패 항목을 점검 결과에 포함한다.
2. 현재 세션에 노출된 skill, 공식 사용자 경로인 `~/.agents/skills`, `codex-notes/skills` 저장소 원본을 구분해서 설명한다.
3. 각 skill의 `name`, `description`, 대표 사용 예시를 한국어로 짧게 정리한다.
4. `codex-notes/skills/codex-system-skills.txt`를 로컬 bundled skill 경로인 `~/.codex/skills/.system`과 비교한다.
5. 누락·추가 항목, 잘못된 대상 또는 깨진 symlink와 doctor 실패를 별도 표시한다.

## 확인 명령

전체 자동 점검:

```bash
./scripts/doctor.sh
```

공식 사용자 skill 디렉터리:

```bash
ls -1 ~/.agents/skills
```

skill 메타데이터:

```bash
for f in ~/.agents/skills/*/SKILL.md; do
  echo "## $f"
  sed -n '1,8p' "$f"
done
```

깨진 symlink:

```bash
find ~/.agents/skills -type l -exec test ! -e {} \; -print
```

저장소 기준 개인 skill:

```bash
find /path/to/codex-notes/skills -maxdepth 2 -name SKILL.md | sort
```

시스템 skill 기준 목록 비교:

```bash
comm -23 \
  <(sed -n '/^[^#[:space:]]/p' /path/to/codex-notes/skills/codex-system-skills.txt | sort) \
  <(find ~/.codex/skills/.system -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
comm -13 \
  <(sed -n '/^[^#[:space:]]/p' /path/to/codex-notes/skills/codex-system-skills.txt | sort) \
  <(find ~/.codex/skills/.system -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
```

## 출력

- `[스킬 목록]`, `[사용 예시]`, `[점검 결과]` 섹션을 사용한다.
- 사용자가 간단히 물으면 표로 짧게 답한다.
- 로컬 파일 확인을 실행했다면 명령과 결과를 요약한다.
- 현재 세션에 아직 로드되지 않은 skill은 “로컬에 정의됨”으로 표현한다.
- `[점검 결과]`에는 doctor의 error/warning 수와 핵심 실패 항목을 포함한다.
- 시스템 skill 기준 목록이 있으면 `[시스템 스킬 비교]` 섹션에 일치 여부, 저장소 기준에서 누락된 skill, 로컬에만 추가된 skill을 표시한다.
