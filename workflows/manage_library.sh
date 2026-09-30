#!/usr/bin/env bash

# Coordinate UI, book components, and the database for library operations.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB="$ROOT_DIR/data/book_database.sh"
UI="$ROOT_DIR/ui/library_screen.sh"

show_all() {
  "$DB" list | "$UI" show
}

add_book() {
  input="${1:-}"
  if [ -z "$input" ]; then
    input="$("$UI" collect-add)" || return
  fi
  IFS='|' read -r requested_title requested_author status rating <<EOF
$input
EOF

  metadata="$(printf '%s|%s\n' "$requested_title" "$requested_author" | "$ROOT_DIR/books/fetch_book_metadata.sh")"
  IFS='|' read -r title author genre year link <<EOF
$metadata
EOF

  if row="$("$DB" add "$title" "$author" "$genre" "$year" "$status" "$rating" "$link")"; then
    "$UI" message "Added $title to your library."
  else
    "$UI" error "Could not add $title. It may already be saved."
    return 1
  fi
}

search_library() {
  term="${1:-}"
  [ -n "$term" ] || term="$("$UI" prompt-search)"
  [ -n "$term" ] || return
  printf '%s\n' "$term" | "$ROOT_DIR/books/search_books.sh" | "$UI" show
}

select_saved_title() {
  "$DB" list | "$UI" select-book
}

update_status() {
  title="${1:-}"
  status="${2:-}"
  [ -n "$title" ] || title="$(select_saved_title)" || return
  [ -n "$status" ] || status="$("$UI" choose-status)" || return
  "$DB" update-status "$title" "$status"
  "$UI" message "Updated $title to $status."
}

update_rating() {
  title="${1:-}"
  rating="${2:-}"
  [ -n "$title" ] || title="$(select_saved_title)" || return
  [ -n "$rating" ] || rating="$("$UI" choose-rating)" || return
  "$DB" update-rating "$title" "$rating"
  "$UI" message "Rated $title $rating out of 5."
}

edit_interests() {
  interests="${1:-}"
  [ -n "$interests" ] || interests="$("$UI" collect-interests)"
  [ -n "$interests" ] || return
  printf '%s\n' "$interests" | tr ',' '\n' | sed 's/^ *//; s/ *$//; /^$/d' > "$ROOT_DIR/data/interests.txt"
  "$UI" message "Updated your recommendation interests."
}

case "${1:-}" in
  list) show_all ;;
  add) add_book "${2:-}" ;;
  search) search_library "${2:-}" ;;
  update-status) update_status "${2:-}" "${3:-}" ;;
  rate) update_rating "${2:-}" "${3:-}" ;;
  interests) edit_interests "${2:-}" ;;
  add-recommendation)
    [ "$#" -ge 8 ] || { echo "Incomplete recommendation." >&2; exit 2; }
    "$DB" add "$2" "$3" "$4" "$5" "want-to-read" "" "$8" >/dev/null
    "$UI" message "Saved $2 to your want-to-read list."
    ;;
  *)
    echo "Usage: $0 {list|add|search|update-status|rate|interests|add-recommendation}" >&2
    exit 2
    ;;
esac
