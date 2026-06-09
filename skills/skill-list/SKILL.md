---
name: skill-list
description: /스킬, 스킬 목록, skill list, 현재 사용 가능한 Codex skill 확인, 로컬 ~/.codex/skills 또는 저장소 skills 목록 점검이 필요할 때 사용한다.
---

# 스킬 목록 확인

## 작업 흐름

1. 사용자가 `/스킬`, `스킬 목록`, `skill list`처럼 요청하면 현재 사용 가능한 skill을 요약한다.
2. 가능하면 현재 세션에 노출된 skill 목록과 로컬 파일시스템의 `~/.codex/skills` 목록을 구분해서 설명한다.
3. 로컬 확인이 필요한 경우 `~/.codex/skills/*/SKILL.md`와 `codex-notes/skills/*/SKILL.md`를 확인한다.
4. 각 skill의 `name`, `description`, 대표 사용 예시를 한국어로 짧게 정리한다.
5. 누락되었거나 symlink가 깨진 skill이 있으면 별도 표시한다.

## 확인 명령

로컬 skill 디렉터리:

```bash
ls -1 ~/.codex/skills
```

skill 메타데이터:

```bash
for f in ~/.codex/skills/*/SKILL.md; do
  echo "## $f"
  sed -n '1,8p' "$f"
done
```

깨진 symlink:

```bash
find ~/.codex/skills -type l -exec test ! -e {} \; -print
```

저장소 기준 개인 skill:

```bash
find /path/to/codex-notes/skills -maxdepth 2 -name SKILL.md | sort
```

## 출력

- `[스킬 목록]`, `[사용 예시]`, `[점검 결과]` 섹션을 사용한다.
- 사용자가 간단히 물으면 표로 짧게 답한다.
- 로컬 파일 확인을 실행했다면 명령과 결과를 요약한다.
- 현재 세션에 아직 로드되지 않은 skill은 “로컬에 정의됨”으로 표현한다.
