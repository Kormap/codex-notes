#!/bin/sh

set -eu

scenario_id=${1:-}
workspace_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$workspace_root"

case $scenario_id in
  SCN-01)
    test -f fixtures/research/source-a.md
    test -f fixtures/research/source-b.md
    ;;
  SCN-02)
    node --test fixtures/api/handler.test.mjs
    ;;
  SCN-03)
    test -f fixtures/review/change.diff
    rg -q 'SELECT.*email' fixtures/review/change.diff
    ;;
  SCN-04)
    node fixtures/shared/validate.mjs
    ;;
  SCN-05)
    node --test fixtures/module-a/module.test.mjs fixtures/module-b/module.test.mjs
    ;;
  *)
    printf 'unknown scenario: %s\n' "$scenario_id" >&2
    exit 2
    ;;
esac
