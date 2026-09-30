#!/usr/bin/env bash

# UI helpers for collecting library input and displaying book records.
set -u

has_gum() { command -v gum >/dev/null 2>&1; }

heading() {
  if has_gum; then
    gum style --foreground 212 --bold --border rounded --padding "0 2" "$1"
  else
    printf '\n=== %s ===\n' "$1"
  fi
}

prompt_value() {
  local label="$1" placeholder="${2:-}"
  if has_gum; then
    gum input --prompt "$label: " --placeholder "$placeholder"
  else
    printf '%s: ' "$label" > /dev/tty
    IFS= read -r value < /dev/tty
    printf '%s\n' "$value"
  fi
}

choose_value() {
  local header="$1"
  shift
  if has_gum; then
    gum choose --header "$header" "$@"
  else
    local index=1 option selection
    printf '%s\n' "$header" > /dev/tty
    for option in "$@"; do
      printf '  %d) %s\n' "$index" "$option" > /dev/tty
      index=$((index + 1))
    done
    printf '> ' > /dev/tty
    IFS= read -r selection < /dev/tty
    [ "$selection" -ge 1 ] 2>/dev/null && [ "$selection" -lt "$index" ] || return 1
    index=1
    for option in "$@"; do
      if [ "$selection" -eq "$index" ]; then
        printf '%s\n' "$option"
        return
      fi
      index=$((index + 1))
    done
    return 1
  fi
}

show_records() {
  heading "Your Library"
  records="$(cat)"
  if [ -z "$records" ]; then
    echo "No matching books yet."
    return
  fi

  printf '%-3s  %-34s  %-24s  %-17s  %-13s  %s\n' "ID" "TITLE" "AUTHOR" "GENRE" "STATUS" "RATING"
  printf '%s\n' "$records" | while IFS='|' read -r id title author genre year status rating link added; do
    [ -n "$rating" ] || rating="—"
    printf '%-3s  %-34.34s  %-24.24s  %-17.17s  %-13s  %s\n' "$id" "$title" "$author" "$genre" "$status" "$rating"
  done
}

select_book() {
  records="$(cat)"
  [ -n "$records" ] || return 1
  options=()
  titles=()
  while IFS='|' read -r id title author genre year status rating link added; do
    options+=("$title — $author [$status]")
    titles+=("$title")
  done <<EOF
$records
EOF

  selected="$(choose_value "Choose a book" "${options[@]}")" || return 1
  index=0
  for option in "${options[@]}"; do
    if [ "$option" = "$selected" ]; then
      printf '%s\n' "${titles[$index]}"
      return
    fi
    index=$((index + 1))
  done
}

case "${1:-}" in
  show)
    show_records
    ;;
  collect-add)
    heading "Add a Book" >&2
    title="$(prompt_value "Title" "e.g. Being Mortal")"
    [ -n "$title" ] || exit 1
    author="$(prompt_value "Author" "optional if cataloged")"
    status="$(choose_value "Reading status" "want-to-read" "reading" "finished" "owned")"
    rating=""
    if [ "$status" = "finished" ]; then
      rating="$(choose_value "Rating" "5" "4.5" "4" "3.5" "3" "2.5" "2" "1" "0")"
    fi
    printf '%s|%s|%s|%s\n' "$title" "$author" "$status" "$rating"
    ;;
  prompt-search)
    prompt_value "Search title, author, genre, or status" "technology"
    ;;
  select-book)
    select_book
    ;;
  choose-status)
    choose_value "New reading status" "want-to-read" "reading" "finished" "owned"
    ;;
  choose-rating)
    choose_value "Rating" "5" "4.5" "4" "3.5" "3" "2.5" "2" "1" "0"
    ;;
  collect-interests)
    heading "Recommendation Interests" >&2
    prompt_value "Comma-separated interests" "AI, healthcare, cities"
    ;;
  message)
    if has_gum; then gum style --foreground 42 "${2:-}"; else echo "${2:-}"; fi
    ;;
  error)
    if has_gum; then gum style --foreground 196 "${2:-}" >&2; else echo "${2:-}" >&2; fi
    ;;
  *)
    echo "Usage: $0 {show|collect-add|prompt-search|select-book|choose-status|choose-rating|collect-interests|message|error}" >&2
    exit 2
    ;;
esac
