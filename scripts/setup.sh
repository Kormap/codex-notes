#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
user_skills_dir=${HOME}/.agents/skills

resolve_directory() {
  CDPATH= cd -- "$1" 2>/dev/null && pwd -P
}

printf '%s\n' '[Setup] Codex user skills'
mkdir -p "$user_skills_dir"

for skill_md in "$repo_root"/skills/*/SKILL.md; do
  [ -f "$skill_md" ] || {
    printf '[FAIL] no repository skills found\n' >&2
    exit 1
  }

  skill_dir=$(dirname -- "$skill_md")
  skill_name=$(basename -- "$skill_dir")
  installed_path=$user_skills_dir/$skill_name

  if [ -L "$installed_path" ]; then
    installed_target=$(resolve_directory "$installed_path" || true)
    expected_target=$(resolve_directory "$skill_dir")
    if [ "$installed_target" != "$expected_target" ]; then
      printf '[FAIL] %s already points to another target: %s\n' "$installed_path" "$(readlink "$installed_path")" >&2
      exit 1
    fi
    printf '[KEEP] %s\n' "$installed_path"
  elif [ -e "$installed_path" ]; then
    printf '[FAIL] %s already exists and is not a symlink\n' "$installed_path" >&2
    exit 1
  else
    ln -s "$skill_dir" "$installed_path"
    printf '[LINK] %s -> %s\n' "$installed_path" "$skill_dir"
  fi

done

printf '%s\n' '[Setup] Git hooks'
git -C "$repo_root" config --local core.hooksPath .githooks
printf '[SET] core.hooksPath=%s\n' "$(git -C "$repo_root" config --local --get core.hooksPath)"

printf '%s\n' '[Setup] Verification'
"$repo_root/scripts/doctor.sh"

printf '%s\n' '[DONE] setup completed; restart Codex if newly linked skills are not visible'
