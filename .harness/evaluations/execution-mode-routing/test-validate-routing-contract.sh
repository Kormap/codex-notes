#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
node "$script_dir/test-validate-routing-contract.mjs" "$@"
