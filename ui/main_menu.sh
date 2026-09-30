#!/usr/bin/env bash

# Main UI loop. It gathers choices and delegates work to workflows.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY="$ROOT_DIR/workflows/manage_library.sh"
RECOMMEND="$ROOT_DIR/workflows/get_recommendations.sh"

options=(
  "Browse Library"
  "Add Book"
  "Search Library"
  "Update Reading Status"
  "Rate a Book"
  "Get Recommendations"
  "Edit Interests"
  "Quit"
)

choose_action() {
  if command -v gum >/dev/null 2>&1; then
    gum choose --cursor.foreground 212 --header "What would you like to do?" "${options[@]}"
  else
    echo "Gum is not installed, so the portable menu is active." >&2
    index=1
    for option in "${options[@]}"; do
      printf '  %d) %s\n' "$index" "$option" >&2
      index=$((index + 1))
    done
    printf '> ' >&2
    IFS= read -r selection
    [ "$selection" -ge 1 ] 2>/dev/null && [ "$selection" -lt "$index" ] || return 1
    printf '%s\n' "${options[$((selection - 1))]}"
  fi
}

pause_screen() {
  if command -v gum >/dev/null 2>&1; then
    gum input --prompt "Press Enter to return to the menu " --placeholder " " >/dev/null
  else
    printf '\nPress Enter to return to the menu...' >&2
    IFS= read -r unused
  fi
}

if command -v gum >/dev/null 2>&1; then
  gum style --foreground 212 --bold --border double --padding "1 3" \
    "STORIES & SPACES" "Romance, mystery, photography, and interiors."
else
  printf '\nSTORIES & SPACES\nRomance, mystery, photography, and interiors.\n\n'
fi

while :; do
  action="$(choose_action)" || break
  case "$action" in
    "Browse Library") "$LIBRARY" list ;;
    "Add Book") "$LIBRARY" add ;;
    "Search Library") "$LIBRARY" search ;;
    "Update Reading Status") "$LIBRARY" update-status ;;
    "Rate a Book") "$LIBRARY" rate ;;
    "Get Recommendations") "$RECOMMEND" ;;
    "Edit Interests") "$LIBRARY" interests ;;
    "Quit") break ;;
  esac
  pause_screen
done

echo "Happy reading."
