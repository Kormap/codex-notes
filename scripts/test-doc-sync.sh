#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
output_root=$(mktemp -d "${TMPDIR:-/tmp}/codex-doc-sync.XXXXXX")
test_root=$output_root/repo
trap 'rm -rf "$output_root"' EXIT
trap 'exit 1' HUP INT TERM
mkdir -p "$test_root/scripts" "$test_root/docs"
cp "$repo_root/scripts/check-doc-sync.sh" "$test_root/scripts/"
cp "$repo_root/.gitattributes" "$test_root/"
git -C "$test_root" init -q
git -C "$test_root" config user.name Fixture
git -C "$test_root" config user.email fixture@example.invalid
git -C "$test_root" config commit.gpgsign false
git -C "$test_root" config core.hooksPath "$test_root/no-hooks"

commit_fixture() {
  git -C "$test_root" add .
  git -C "$test_root" commit -qm "$1"
  git -C "$test_root" rev-parse HEAD
}

check_update() {
  expected=$1
  shift
  result=0
  printf '%s\n' "$@" | sh "$test_root/scripts/check-doc-sync.sh" > "$output_root/output" 2>&1 || result=$?
  if { [ "$expected" = pass ] && [ "$result" -ne 0 ]; } || \
     { [ "$expected" = fail ] && [ "$result" -eq 0 ]; }; then
    cat "$output_root/output" >&2
    printf '[FAIL] unexpected doc synchronization result\n' >&2
    exit 1
  fi
}

zero=0000000000000000000000000000000000000000

printf 'English baseline\n' > "$test_root/AGENTS.md"
old=$(commit_fixture 'Before translation')
check_update pass "refs/heads/test $old refs/heads/test $zero"
printf 'English paired\n' > "$test_root/AGENTS.md"
printf 'Korean paired\n' > "$test_root/docs/AGENTS.ko.md"
paired=$(commit_fixture 'Add translation with source update')
check_update pass "refs/heads/test $paired refs/heads/test $old"
check_update pass "refs/heads/test $paired refs/heads/test $zero"
git -C "$test_root" update-ref refs/remotes/origin/main "$paired"

printf 'English only\n' > "$test_root/AGENTS.md"
broken=$(commit_fixture 'Unpaired change')
[ -z "$(git -C "$test_root" status --porcelain)" ]
check_update fail "refs/heads/test $broken refs/heads/test $paired"
check_update fail "refs/heads/test $broken refs/heads/test $zero"
check_update pass "refs/heads/test $zero refs/heads/test $broken"
check_update fail "refs/heads/one $paired refs/heads/one $old" "refs/heads/two $broken refs/heads/two $paired"

printf 'English next\n' > "$test_root/AGENTS.md"
printf 'Korean next\n' > "$test_root/docs/AGENTS.ko.md"
next_pair=$(commit_fixture 'Paired update')
check_update pass "refs/heads/test $next_pair refs/heads/test $broken"
check_update fail "refs/heads/test $next_pair refs/heads/test $paired"
rm "$test_root/docs/AGENTS.ko.md"
deleted=$(commit_fixture 'Delete translation only')
check_update fail "refs/heads/test $deleted refs/heads/test $next_pair"
check_update fail "refs/heads/test $deleted refs/heads/test ffffffffffffffffffffffffffffffffffffffff"

git -C "$test_root" config core.autocrlf true
git -C "$test_root" checkout-index --all --prefix="$output_root/checkout/"
if LC_ALL=C grep -q "$(printf '\r')" "$output_root/checkout/scripts/check-doc-sync.sh" "$output_root/checkout/AGENTS.md"; then
  printf '[FAIL] CRLF found in LF checkout\n' >&2
  exit 1
fi
printf '[PASS] committed pairing, new/deleted/multiple refs, missing objects and LF checkout\n'
