#!/usr/bin/env bash

# Read candidates from stdin, remove duplicates/library matches, and rank five.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
temp_candidates="$(mktemp "${TMPDIR:-/tmp}/book-candidates.XXXXXX")"
temp_unique="$(mktemp "${TMPDIR:-/tmp}/book-unique.XXXXXX")"
trap 'rm -f "$temp_candidates" "$temp_unique"' EXIT INT TERM

cat > "$temp_candidates"

sort -t'|' -k1,1nr "$temp_candidates" | awk -F'|' '
  NF >= 8 {
    key=tolower($2 "|" $3)
    if (!seen[key]++) print
  }
' > "$temp_unique"

count=0
while IFS= read -r candidate; do
  IFS='|' read -r score title author genre year strategy reason link <<EOF
$candidate
EOF
  if ! "$ROOT_DIR/data/book_database.sh" exists "$title" "$author"; then
    printf '%s\n' "$candidate"
    count=$((count + 1))
  fi
  [ "$count" -ge 5 ] && break
done < "$temp_unique"
