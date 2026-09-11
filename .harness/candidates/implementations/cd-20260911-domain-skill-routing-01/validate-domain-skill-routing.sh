#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../../.." && pwd)
baseline=$repo_root/skills/dev-harness/SKILL.md
candidate=$script_dir/skills/dev-harness/dev-harness.SKILL.candidate.txt

if [ ! -f "$baseline" ] || [ ! -f "$candidate" ]; then
  printf '%s\n' '[FAIL] baseline or candidate dev-harness SKILL.md is missing' >&2
  exit 2
fi

for heading in '### 1. 작업 유형' '### 2. 주 도메인' '### 3. 교차 관심사' '### 4. 테스트'; do
  grep -Fq "$heading" "$candidate" || {
    printf '%s\n' "[FAIL] candidate is missing routing stage: $heading" >&2
    exit 1
  }
done

previous=0
for heading in '### 1. 작업 유형' '### 2. 주 도메인' '### 3. 교차 관심사' '### 4. 테스트'; do
  current=$(grep -nF "$heading" "$candidate" | cut -d: -f1)
  if [ "$current" -le "$previous" ]; then
    printf '%s\n' '[FAIL] routing stages are out of order' >&2
    exit 1
  fi
  previous=$current
done

for skill in \
  pr-review engineering-standards frontend-ui-review jpa-performance-review \
  mybatis-xml-review query-plan-review data-migration spring-transaction-audit \
  logging-observability deploy-checklist test-generator; do
  [ -f "$repo_root/skills/$skill/SKILL.md" ] || {
    printf '%s\n' "[FAIL] delegated skill is not installed in repository: $skill" >&2
    exit 1
  }
  grep -Fq "\`$skill\`" "$candidate" || {
    printf '%s\n' "[FAIL] delegated skill is not routed by candidate: $skill" >&2
    exit 1
  }
done

grep -Fq 'Task와 evaluator를 선택한 뒤' "$candidate" || {
  printf '%s\n' '[FAIL] routing does not preserve task/evaluator selection precedence' >&2
  exit 1
}
grep -Fq '최종 `PASS`, `FAIL`, `BLOCKED` 판정은 Harness가 유지한다' "$candidate" || {
  printf '%s\n' '[FAIL] final evaluator ownership is not preserved' >&2
  exit 1
}
grep -Fq 'Skill 조합은 실행 권한을 확대하지 않는다' "$candidate" || {
  printf '%s\n' '[FAIL] routing does not preserve authority boundaries' >&2
  exit 1
}

cmp -s "$baseline" "$candidate" || {
  printf '%s\n' '[FAIL] promoted dev-harness differs from the accepted candidate snapshot' >&2
  exit 1
}

printf '%s\n' '[PASS] promoted dev-harness matches the four-stage candidate routing contract'
