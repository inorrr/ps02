#!/usr/bin/env bash

# Lightweight end-to-end checks that use an isolated temporary library.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/book-manager-tests.XXXXXX")"
export BOOK_MANAGER_DB="$TEST_DIR/books.csv"
export BOOK_MANAGER_AGENT_DELAY=0
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

passed=0
failed=0

pass() {
  passed=$((passed + 1))
  printf '✓ %s\n' "$1"
}

fail() {
  failed=$((failed + 1))
  printf '✗ %s\n' "$1" >&2
}

assert_contains() {
  name="$1"
  text="$2"
  expected="$3"
  if printf '%s\n' "$text" | grep -Fq "$expected"; then pass "$name"; else fail "$name"; fi
}

"$ROOT_DIR/data/book_database.sh" init

metadata="$(printf 'Rebecca|Daphne du Maurier\n' | "$ROOT_DIR/books/fetch_book_metadata.sh")"
assert_contains "metadata enrichment" "$metadata" "Gothic Mystery|1938"

add_output="$("$ROOT_DIR/workflows/manage_library.sh" add 'Rebecca|Daphne du Maurier|want-to-read|')"
assert_contains "add workflow" "$add_output" "Added Rebecca"

if ! "$ROOT_DIR/data/book_database.sh" add "Rebecca" "Daphne du Maurier" "Gothic Mystery" "1938" "owned" "" "" >/dev/null 2>&1; then
  pass "duplicate prevention"
else
  fail "duplicate prevention"
fi

if ! "$ROOT_DIR/data/book_database.sh" add "Invalid Rating" "Test Author" "Test" "2026" "finished" "5.5" "" >/dev/null 2>&1; then
  pass "rating validation"
else
  fail "rating validation"
fi

search_output="$(printf 'mystery\n' | "$ROOT_DIR/books/search_books.sh")"
assert_contains "search through stdin" "$search_output" "Rebecca"

"$ROOT_DIR/workflows/manage_library.sh" update-status "Rebecca" "finished" >/dev/null
"$ROOT_DIR/workflows/manage_library.sh" rate "Rebecca" "4.5" >/dev/null
updated="$("$ROOT_DIR/data/book_database.sh" search "Rebecca")"
assert_contains "status update" "$updated" "|finished|4.5|"

candidates='99|Rebecca|Daphne du Maurier|Gothic Mystery|1938|history|already saved|https://example.com
98|Novel A|Writer A|Fiction|2020|interests|first version|https://example.com/a
97|Novel A|Writer A|Fiction|2020|discovery|duplicate|https://example.com/a
96|Novel B|Writer B|History|2019|discovery|new book|https://example.com/b'
refined="$(printf '%s\n' "$candidates" | "$ROOT_DIR/recommendations/refine_recommendations.sh")"
assert_contains "refinement keeps new candidates" "$refined" "Novel A"
if ! printf '%s\n' "$refined" | grep -Fq "Rebecca"; then
  pass "refinement excludes saved books"
else
  fail "refinement excludes saved books"
fi

recommendations="$("$ROOT_DIR/workflows/get_recommendations.sh" --non-interactive)"
assert_contains "parallel workflow completes" "$recommendations" "Discovery agent finished"
assert_contains "recommendations are displayed" "$recommendations" "1. "
assert_contains "personalized interior recommendation" "$recommendations" "Interior Design"
assert_contains "personalized story recommendation" "$recommendations" "Literary Mystery"

shell_refs="$(grep -l 'books\.csv' \
  "$ROOT_DIR/app.sh" "$ROOT_DIR"/data/*.sh "$ROOT_DIR"/books/*.sh \
  "$ROOT_DIR"/recommendations/*.sh "$ROOT_DIR"/ui/*.sh "$ROOT_DIR"/workflows/*.sh \
  | sed "s|$ROOT_DIR/||")"
if [ "$shell_refs" = "data/book_database.sh" ]; then
  pass "database access boundary"
else
  fail "database access boundary"
  printf '  Unexpected references: %s\n' "$shell_refs" >&2
fi

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
