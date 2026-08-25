#!/bin/sh

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
exec "$script_dir/../../../scripts/doctor.sh" "$@"
