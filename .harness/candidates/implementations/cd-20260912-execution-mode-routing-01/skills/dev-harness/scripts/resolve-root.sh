#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
source_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)

is_harness_root() {
  [ -f "$1/.harness/baseline/README.md" ] &&
    [ -f "$1/scripts/doctor.sh" ] &&
    [ -f "$1/skills/dev-harness/SKILL.md" ]
}

if is_harness_root "$source_root"; then
  printf '%s\n' "$source_root"
  exit 0
fi

if [ -z "${HOME:-}" ]; then
  printf '%s\n' '[FAIL] HOME is required for a copied Harness skill; run setup.sh from codex-notes' >&2
  exit 1
fi

root_record=$HOME/.agents/codex-notes-root
if [ ! -f "$root_record" ]; then
  printf '%s\n' '[FAIL] central Harness location is missing; run setup.sh from codex-notes' >&2
  exit 1
fi
IFS= read -r configured_root < "$root_record" || configured_root=
case "$configured_root" in
  /*) ;;
  *)
    printf '%s\n' '[FAIL] central Harness location must be an absolute POSIX path; run setup.sh from codex-notes' >&2
    exit 1
    ;;
esac
resolved_root=$(CDPATH= cd -- "$configured_root" 2>/dev/null && pwd -P) || {
  printf '%s\n' '[FAIL] central Harness location is unavailable; run setup.sh from codex-notes' >&2
  exit 1
}
if ! is_harness_root "$resolved_root"; then
  printf '%s\n' '[FAIL] configured location is not a codex-notes Harness repository' >&2
  exit 1
fi
printf '%s\n' "$resolved_root"
