#!/usr/bin/env bash

# Data abstraction layer. This is the only application file that accesses books.csv.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB_FILE="${BOOK_MANAGER_DB:-$ROOT_DIR/data/books.csv}"
HEADER="id,title,author,genre,year,status,rating,link,date_added"

usage() {
  echo "Usage: $0 {init|list|search|add|exists|update-status|update-rating|delete|stats}" >&2
  exit 2
}

clean_field() {
  printf '%s' "$1" | tr '\n\r,|' '    ' | sed 's/^ *//; s/ *$//; s/  */ /g'
}

valid_status() {
  case "$1" in
    owned|want-to-read|reading|finished) return 0 ;;
    *) return 1 ;;
  esac
}

valid_rating() {
  [ -z "$1" ] || awk -v value="$1" 'BEGIN { exit !(value ~ /^([0-4]([.][05])?|5([.]0)?)$/) }'
}

init_db() {
  mkdir -p "$(dirname "$DB_FILE")"
  if [ ! -f "$DB_FILE" ]; then
    printf '%s\n' "$HEADER" > "$DB_FILE"
  fi
}

emit_rows() {
  awk -F',' 'NR > 1 { OFS="|"; print $1,$2,$3,$4,$5,$6,$7,$8,$9 }' "$DB_FILE"
}

find_id() {
  local title
  title="$(clean_field "$1")"
  awk -F',' -v title="$title" 'NR > 1 && tolower($2) == tolower(title) { print $1; exit }' "$DB_FILE"
}

init_db
command="${1:-}"

case "$command" in
  init)
    ;;
  list)
    emit_rows
    ;;
  search)
    term="$(clean_field "${2:-}")"
    emit_rows | awk -F'|' -v term="$term" 'BEGIN { IGNORECASE=1 } index(tolower($0), tolower(term)) > 0'
    ;;
  exists)
    title="$(clean_field "${2:-}")"
    author="$(clean_field "${3:-}")"
    awk -F',' -v title="$title" -v author="$author" '
      NR > 1 && tolower($2) == tolower(title) && (author == "" || tolower($3) == tolower(author)) { found=1 }
      END { exit !found }
    ' "$DB_FILE"
    ;;
  add)
    [ "$#" -ge 8 ] || usage
    title="$(clean_field "$2")"
    author="$(clean_field "$3")"
    genre="$(clean_field "$4")"
    year="$(clean_field "$5")"
    status="$(clean_field "$6")"
    rating="$(clean_field "$7")"
    link="$(clean_field "$8")"

    [ -n "$title" ] && [ -n "$author" ] || { echo "Title and author are required." >&2; exit 1; }
    valid_status "$status" || { echo "Invalid status: $status" >&2; exit 1; }
    valid_rating "$rating" || { echo "Rating must be blank or 0-5 in half-point steps." >&2; exit 1; }
    if "$0" exists "$title" "$author"; then
      echo "That book is already in the library." >&2
      exit 1
    fi

    next_id="$(awk -F',' 'NR > 1 && $1+0 > max { max=$1+0 } END { print max+1 }' "$DB_FILE")"
    added="$(date +%Y-%m-%d)"
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$next_id" "$title" "$author" "$genre" "$year" "$status" "$rating" "$link" "$added" >> "$DB_FILE"
    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
      "$next_id" "$title" "$author" "$genre" "$year" "$status" "$rating" "$link" "$added"
    ;;
  update-status)
    id="$(find_id "${2:-}")"
    status="$(clean_field "${3:-}")"
    [ -n "$id" ] || { echo "Book not found: ${2:-}" >&2; exit 1; }
    valid_status "$status" || { echo "Invalid status: $status" >&2; exit 1; }
    tmp_file="$(mktemp "${TMPDIR:-/tmp}/book-db.XXXXXX")"
    awk -F',' -v OFS=',' -v id="$id" -v value="$status" '{ if ($1 == id) $6=value; print }' "$DB_FILE" > "$tmp_file"
    mv "$tmp_file" "$DB_FILE"
    ;;
  update-rating)
    id="$(find_id "${2:-}")"
    rating="$(clean_field "${3:-}")"
    [ -n "$id" ] || { echo "Book not found: ${2:-}" >&2; exit 1; }
    valid_rating "$rating" || { echo "Rating must be blank or 0-5 in half-point steps." >&2; exit 1; }
    tmp_file="$(mktemp "${TMPDIR:-/tmp}/book-db.XXXXXX")"
    awk -F',' -v OFS=',' -v id="$id" -v value="$rating" '{ if ($1 == id) $7=value; print }' "$DB_FILE" > "$tmp_file"
    mv "$tmp_file" "$DB_FILE"
    ;;
  delete)
    id="$(find_id "${2:-}")"
    [ -n "$id" ] || { echo "Book not found: ${2:-}" >&2; exit 1; }
    tmp_file="$(mktemp "${TMPDIR:-/tmp}/book-db.XXXXXX")"
    awk -F',' -v id="$id" '$1 != id' "$DB_FILE" > "$tmp_file"
    mv "$tmp_file" "$DB_FILE"
    ;;
  stats)
    emit_rows | awk -F'|' '
      { total++; status[$6]++ }
      END {
        printf "total|%d\n", total
        printf "reading|%d\n", status["reading"]
        printf "finished|%d\n", status["finished"]
        printf "want-to-read|%d\n", status["want-to-read"]
        printf "owned|%d\n", status["owned"]
      }
    '
    ;;
  *) usage ;;
esac
