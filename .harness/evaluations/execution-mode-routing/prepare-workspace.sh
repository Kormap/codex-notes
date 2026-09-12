#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
  printf 'usage: %s <new-workspace> <dev-harness-skill>\n' "$0" >&2
  exit 2
fi

destination=$1
skill_source=$2
skill_source_dir=$(CDPATH= cd -- "$(dirname -- "$skill_source")" && pwd -P)
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

if [ -e "$destination" ]; then
  printf 'destination already exists: %s\n' "$destination" >&2
  exit 2
fi
if [ ! -f "$skill_source" ]; then
  printf 'skill source not found: %s\n' "$skill_source" >&2
  exit 2
fi

mkdir -p "$destination"
cp -R "$script_dir/workspace/." "$destination/"
(
  cd "$destination"
  git init -q
  git config user.name 'Harness Fixture'
  git config user.email 'harness-fixture@example.invalid'
  git add .
  GIT_AUTHOR_DATE='2026-09-11T00:00:00Z' \
  GIT_COMMITTER_DATE='2026-09-11T00:00:00Z' \
    git -c commit.gpgsign=false commit -q -m 'execution-mode-routing fixture v1'
  printf '.agents/\n' >> .git/info/exclude
)

mkdir -p "$destination/.agents/skills/dev-harness"
cp -R "$skill_source_dir/." "$destination/.agents/skills/dev-harness/"

git -C "$destination" rev-parse HEAD
