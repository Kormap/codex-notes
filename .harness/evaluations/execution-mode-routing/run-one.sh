#!/bin/sh

set -eu

if [ "$#" -ne 5 ]; then
  printf 'usage: %s <scenario> <workspace> <result-dir> <baseline-skill> <frozen-config>\n' "$0" >&2
  exit 2
fi

scenario=$1
workspace=$2
result_dir=$3
baseline_skill=$4
frozen_config=$5
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
central_root=$(sh "$script_dir/../../../skills/dev-harness/scripts/resolve-root.sh")
prompt_file=$script_dir/prompts/$scenario.txt
local_skill=$workspace/.agents/skills/dev-harness/SKILL.md
installed_skill=${HOME}/.agents/skills/dev-harness/SKILL.md
original_codex_home=${CODEX_HOME:-${HOME}/.codex}
evaluation_home=$result_dir/home
runtime_codex_home=$result_dir/codex-home

test -f "$prompt_file"
test -f "$local_skill"
test -f "$baseline_skill"
test -f "$frozen_config"
test -f "$original_codex_home/auth.json"
mkdir -p "$result_dir"
mkdir -p "$evaluation_home/.agents"
mkdir -p "$runtime_codex_home"
printf '%s\n' "$central_root" > "$evaluation_home/.agents/codex-notes-root"
cp "$frozen_config" "$runtime_codex_home/config.toml"
chmod 600 "$runtime_codex_home/config.toml"
ln -s "$original_codex_home/auth.json" "$runtime_codex_home/auth.json"

"$script_dir/preflight.sh" "$workspace" "$baseline_skill" "$runtime_codex_home/config.toml" > "$result_dir/preflight.txt"
HOME="$evaluation_home" sh "$workspace/.agents/skills/dev-harness/scripts/resolve-root.sh" >/dev/null
printf 'resolver=PASS\n' >> "$result_dir/preflight.txt"
prompt=$(sed -n '1p' "$prompt_file")
skills_override=$(printf 'skills.config=[{path="%s",enabled=false},{path="%s",enabled=true}]' "$installed_skill" "$local_skill")

set +e
HOME="$evaluation_home" CODEX_HOME="$runtime_codex_home" codex exec \
  --strict-config \
  --ephemeral \
  --json \
  --enable multi_agent \
  --approve-for-me \
  -C "$workspace" \
  -m gpt-5.6-terra \
  -c 'model_reasoning_effort="medium"' \
  -c "$skills_override" \
  --output-schema "$script_dir/routing-result.schema.json" \
  --output-last-message "$result_dir/result.json" \
  "$prompt" > "$result_dir/events.jsonl" 2> "$result_dir/stderr.txt"
codex_status=$?
set -e

printf '%s\n' "$codex_status" > "$result_dir/codex-exit-code.txt"
if [ "$codex_status" -ne 0 ]; then
  printf 'codex exec failed for %s with exit code %s\n' "$scenario" "$codex_status" >&2
  exit "$codex_status"
fi

set +e
"$script_dir/validate-routing-contract.sh" "$result_dir/result.json" "$scenario" "$workspace" \
  > "$result_dir/validation.txt" 2>&1
validation_status=$?
set -e
printf '%s\n' "$validation_status" > "$result_dir/validation-exit-code.txt"

exit "$validation_status"
