#!/usr/bin/env bash

# UI helpers for recommendation progress, results, and selection.
set -u

has_gum() { command -v gum >/dev/null 2>&1; }

case "${1:-}" in
  heading)
    if has_gum; then
      gum style --foreground 81 --bold --border double --padding "0 2" "Your Recommendation Studio"
    else
      printf '\n=== Your Recommendation Studio ===\n'
    fi
    ;;
  progress)
    state="${2:-running}"
    label="${3:-Agent}"
    if [ "$state" = "running" ]; then icon="◌"; color=214; else icon="✓"; color=42; fi
    if has_gum; then
      gum style --foreground "$color" "$icon $label"
    else
      printf '[%s] %s\n' "$state" "$label"
    fi
    ;;
  show)
    file="${2:?recommendation file required}"
    number=1
    while IFS='|' read -r score title author genre year strategy reason link; do
      printf '\n%d. %s — %s (%s)\n' "$number" "$title" "$author" "$year"
      printf '   %-10s · %-16s · score %s\n' "$strategy" "$genre" "$score"
      printf '   %s\n' "$reason"
      number=$((number + 1))
    done < "$file"
    ;;
  choose)
    file="${2:?recommendation file required}"
    candidates=()
    options=("Skip — keep browsing")
    while IFS= read -r candidate; do
      candidates+=("$candidate")
      IFS='|' read -r score title author genre year strategy reason link <<EOF
$candidate
EOF
      options+=("$title — $author [$strategy]")
    done < "$file"

    if has_gum; then
      selected="$(gum choose --header "Save one to your want-to-read list?" "${options[@]}")" || exit 0
    else
      printf '\nSave one to your want-to-read list?\n' > /dev/tty
      index=0
      for option in "${options[@]}"; do
        printf '  %d) %s\n' "$index" "$option" > /dev/tty
        index=$((index + 1))
      done
      printf '> ' > /dev/tty
      IFS= read -r choice < /dev/tty
      [ "${choice:-0}" -ge 1 ] 2>/dev/null || exit 0
      candidate_index=$((choice - 1))
      [ "$candidate_index" -lt "${#candidates[@]}" ] || exit 0
      printf '%s\n' "${candidates[$candidate_index]}"
      exit 0
    fi

    [ "$selected" != "${options[0]}" ] || exit 0
    index=1
    for option in "${options[@]:1}"; do
      if [ "$option" = "$selected" ]; then
        printf '%s\n' "${candidates[$((index - 1))]}"
        exit 0
      fi
      index=$((index + 1))
    done
    ;;
  *)
    echo "Usage: $0 {heading|progress STATE LABEL|show FILE|choose FILE}" >&2
    exit 2
    ;;
esac
