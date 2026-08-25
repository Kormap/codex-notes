#!/bin/sh

set -u

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
user_skills_dir=${HOME}/.agents/skills
system_skills_dir=${HOME}/.codex/skills/.system
error_count=0
warning_count=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  error_count=$((error_count + 1))
}

warn() {
  printf '[WARN] %s\n' "$1" >&2
  warning_count=$((warning_count + 1))
}

make_temp() {
  mktemp "${TMPDIR:-/tmp}/codex-notes-doctor.XXXXXX"
}

repo_skills=$(make_temp) || exit 1
installed_skills=$(make_temp) || exit 1
baseline_skills=$(make_temp) || exit 1
actual_system_skills=$(make_temp) || exit 1
link_errors=$(make_temp) || exit 1
broken_symlinks=$(make_temp) || exit 1
all_installed_skills=$(make_temp) || exit 1
extra_installed_skills=$(make_temp) || exit 1
trap 'rm -f "$repo_skills" "$installed_skills" "$baseline_skills" "$actual_system_skills" "$link_errors" "$broken_symlinks" "$all_installed_skills" "$extra_installed_skills"' EXIT HUP INT TERM

printf '%s\n' '[Repository]'

if git -C "$repo_root" diff --check HEAD --; then
  pass 'git diff whitespace check'
else
  fail 'git diff contains whitespace errors'
fi

agents_changed=$(git -C "$repo_root" diff --name-only HEAD -- AGENTS.md)
korean_agents_changed=$(git -C "$repo_root" diff --name-only HEAD -- docs/AGENTS.ko.md)
if { [ -n "$agents_changed" ] && [ -z "$korean_agents_changed" ]; } || \
   { [ -z "$agents_changed" ] && [ -n "$korean_agents_changed" ]; }; then
  fail 'AGENTS.md and docs/AGENTS.ko.md must change together'
else
  pass 'AGENTS.md translation change pairing'
fi

configured_hooks_path=$(git -C "$repo_root" config --local --get core.hooksPath || true)
if [ "$configured_hooks_path" != '.githooks' ]; then
  fail 'core.hooksPath must be .githooks'
else
  pass 'core.hooksPath configuration'
fi

for hook_name in pre-push post-merge post-rewrite; do
  if [ ! -x "$repo_root/.githooks/$hook_name" ]; then
    fail ".githooks/$hook_name is missing or not executable"
  fi
done

for executable_script in scripts/setup.sh scripts/doctor.sh skills/skill-list/scripts/doctor.sh; do
  if [ ! -x "$repo_root/$executable_script" ]; then
    fail "$executable_script is missing or not executable"
  fi
done

shell_syntax_failed=0
for shell_script in "$repo_root"/scripts/*.sh "$repo_root"/skills/*/scripts/*.sh "$repo_root"/.githooks/*; do
  [ -f "$shell_script" ] || continue
  if ! sh -n "$shell_script"; then
    fail "shell syntax error: ${shell_script#"$repo_root"/}"
    shell_syntax_failed=1
  fi
done
if [ "$shell_syntax_failed" -eq 0 ]; then
  pass 'doctor and Git hook shell syntax'
fi

printf '%s\n' '[Skills]'

for skill_md in "$repo_root"/skills/*/SKILL.md; do
  if [ ! -f "$skill_md" ]; then
    fail 'no repository skills found'
    break
  fi

  skill_dir=$(dirname -- "$skill_md")
  skill_name=$(basename -- "$skill_dir")
  printf '%s\n' "$skill_name" >> "$repo_skills"

  first_line=$(sed -n '1p' "$skill_md")
  frontmatter_end=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$skill_md")
  declared_name=$(awk 'NR > 1 && /^---$/ { exit } /^name:[[:space:]]*/ { sub(/^name:[[:space:]]*/, ""); print; exit }' "$skill_md" | tr -d '"')
  description=$(awk 'NR > 1 && /^---$/ { exit } /^description:[[:space:]]*/ { sub(/^description:[[:space:]]*/, ""); print; exit }' "$skill_md")

  if [ "$first_line" != '---' ] || [ -z "$frontmatter_end" ]; then
    fail "$skill_name: invalid SKILL.md frontmatter boundary"
  elif [ "$declared_name" != "$skill_name" ]; then
    fail "$skill_name: frontmatter name does not match directory"
  elif [ -z "$description" ]; then
    fail "$skill_name: description is empty"
  fi

  metadata_file=$skill_dir/agents/openai.yaml
  if [ ! -f "$metadata_file" ]; then
    fail "$skill_name: agents/openai.yaml is missing"
  elif ! grep -Eq '^interface:[[:space:]]*$' "$metadata_file" || \
       ! grep -Eq '^[[:space:]]+display_name:' "$metadata_file" || \
       ! grep -Eq '^[[:space:]]+short_description:' "$metadata_file"; then
    fail "$skill_name: agents/openai.yaml is missing required interface metadata"
  fi

  if ! grep -Fq "skills/$skill_name/README.md" "$repo_root/README.md"; then
    fail "$skill_name: README skill index entry is missing"
  fi
done

sort -u "$repo_skills" -o "$repo_skills"

find "$repo_root" -path "$repo_root/.git" -prune -o -type f -name '*.md' -print | while IFS= read -r markdown_file; do
  grep -Eo '\]\([^)]*\)' "$markdown_file" 2>/dev/null | sed -e 's/^](//' -e 's/)$//' | while IFS= read -r markdown_link; do
    case "$markdown_link" in
      ''|'#'*|http://*|https://*|mailto:*) continue ;;
    esac
    relative_path=${markdown_link%%#*}
    if [ -n "$relative_path" ] && [ ! -e "$(dirname -- "$markdown_file")/$relative_path" ]; then
      printf '%s: %s\n' "${markdown_file#"$repo_root"/}" "$markdown_link" >> "$link_errors"
    fi
  done
done

if [ -s "$link_errors" ]; then
  while IFS= read -r broken_link; do
    fail "broken Markdown link: $broken_link"
  done < "$link_errors"
else
  pass 'SKILL.md metadata and Markdown links'
fi

printf '%s\n' '[User installation]'

if [ ! -d "$user_skills_dir" ]; then
  fail "$user_skills_dir does not exist"
else
  find "$user_skills_dir" -mindepth 1 -maxdepth 1 -type l ! -exec test -e {} \; -print | while IFS= read -r broken_link; do
    printf '%s\n' "$broken_link" >> "$broken_symlinks"
  done

  if [ -s "$broken_symlinks" ]; then
    while IFS= read -r broken_link; do
      fail "broken user skill symlink: $broken_link"
    done < "$broken_symlinks"
  fi

  while IFS= read -r skill_name; do
    installed_path=$user_skills_dir/$skill_name
    expected_path=$repo_root/skills/$skill_name
    if [ ! -L "$installed_path" ]; then
      fail "$skill_name: official user skill symlink is missing"
      continue
    fi

    installed_target=$(CDPATH= cd -- "$installed_path" 2>/dev/null && pwd -P)
    expected_target=$(CDPATH= cd -- "$expected_path" && pwd -P)
    if [ "$installed_target" != "$expected_target" ]; then
      fail "$skill_name: symlink target differs from repository"
    else
      printf '%s\n' "$skill_name" >> "$installed_skills"
    fi
  done < "$repo_skills"

  for installed_md in "$user_skills_dir"/*/SKILL.md; do
    [ -f "$installed_md" ] || continue
    basename -- "$(dirname -- "$installed_md")"
  done | sort -u > "$all_installed_skills"

  comm -13 "$repo_skills" "$all_installed_skills" > "$extra_installed_skills"
  if [ -s "$extra_installed_skills" ]; then
    while IFS= read -r extra_skill; do
      [ -n "$extra_skill" ] && warn "$extra_skill: user-only skill is installed"
    done < "$extra_installed_skills"
  fi

  if [ "$(wc -l < "$installed_skills" | tr -d ' ')" = "$(wc -l < "$repo_skills" | tr -d ' ')" ]; then
    pass 'all repository skills are linked from the official user path'
  fi
fi

printf '%s\n' '[System baseline]'

sed -n '/^[^#[:space:]]/p' "$repo_root/skills/codex-system-skills.txt" | sort -u > "$baseline_skills"
if [ ! -d "$system_skills_dir" ]; then
  warn "$system_skills_dir is unavailable; bundled-skill comparison skipped"
else
  find "$system_skills_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -u > "$actual_system_skills"
  missing_system=$(comm -23 "$baseline_skills" "$actual_system_skills")
  extra_system=$(comm -13 "$baseline_skills" "$actual_system_skills")
  if [ -n "$missing_system" ]; then
    fail "bundled skills missing locally: $(printf '%s' "$missing_system" | tr '\n' ' ')"
  fi
  if [ -n "$extra_system" ]; then
    warn "bundled skills present only locally: $(printf '%s' "$extra_system" | tr '\n' ' ')"
  fi
  if [ -z "$missing_system" ] && [ -z "$extra_system" ]; then
    pass 'bundled-skill baseline matches local installation'
  fi
fi

printf '[Summary] errors=%s warnings=%s\n' "$error_count" "$warning_count"
[ "$error_count" -eq 0 ]
