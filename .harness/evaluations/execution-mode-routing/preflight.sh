#!/bin/sh

set -eu

if [ "$#" -ne 3 ]; then
  printf 'usage: %s <workspace> <dev-harness-skill> <frozen-config>\n' "$0" >&2
  exit 2
fi

workspace=$1
skill_source=$2
frozen_config=$3
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
expected_commit=$(tr -d '[:space:]' < "$script_dir/fixture-commit.txt")
actual_commit=$(git -C "$workspace" rev-parse HEAD)
expected_skill_hash=$(shasum -a 256 "$skill_source" | awk '{print $1}')
actual_skill_hash=$(shasum -a 256 "$workspace/.agents/skills/dev-harness/SKILL.md" | awk '{print $1}')
workspace_skill_count=$(find "$workspace/.agents/skills" -path '*/dev-harness/SKILL.md' -type f | wc -l | tr -d '[:space:]')

test "$actual_commit" = "$expected_commit"
test "$workspace_skill_count" = '1'
test "$actual_skill_hash" = "$expected_skill_hash"
test -f "$workspace/.agents/skills/dev-harness/scripts/resolve-root.sh"
git -C "$workspace" diff --quiet --
test -z "$(git -C "$workspace" status --porcelain)"

for required_path in \
  fixtures/research/source-a.md \
  fixtures/research/source-b.md \
  fixtures/api/handler.mjs \
  fixtures/api/handler.test.mjs \
  fixtures/review/change.diff \
  fixtures/shared/app.conf \
  fixtures/shared/migrations/V002__account_index.sql \
  fixtures/shared/validate.mjs \
  fixtures/module-a/module.mjs \
  fixtures/module-a/module.test.mjs \
  fixtures/module-b/module.mjs \
  fixtures/module-b/module.test.mjs \
  evaluation/validate-scenario.sh
do
  test -f "$workspace/$required_path"
done

for required_command in codex git node rg shasum; do
  command -v "$required_command" >/dev/null 2>&1
done

installed_skill=${HOME}/.agents/skills/dev-harness/SKILL.md
test -f "$installed_skill"
installed_skill_hash=$(shasum -a 256 "$installed_skill" | awk '{print $1}')

codex_version=$(codex --version 2>/dev/null)
multi_agent_state=$(codex features list 2>/dev/null | awk '$1 == "multi_agent" { print $2 ":" $3 }')
test "$multi_agent_state" = 'stable:true'

test -f "$frozen_config"
config_hash=$(shasum -a 256 "$frozen_config" | awk '{print $1}')

printf 'fixture_commit=%s\n' "$actual_commit"
printf 'skill_catalog_count=%s\n' "$workspace_skill_count"
printf 'skill_sha256=%s\n' "$actual_skill_hash"
printf 'installed_skill_sha256=%s\n' "$installed_skill_hash"
printf 'config_sha256=%s\n' "$config_hash"
printf 'codex_version=%s\n' "$codex_version"
printf 'multi_agent=%s\n' "$multi_agent_state"
