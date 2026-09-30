#!/usr/bin/env bash

# Run three agents concurrently, synchronize them, pipe results, and display.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UI="$ROOT_DIR/ui/recommendations_screen.sh"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/book-recs.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT INT TERM

"$UI" heading

"$ROOT_DIR/recommendations/recommend_from_history.sh" > "$work_dir/history.txt" &
history_pid=$!
"$UI" progress running "History agent is reading your library"

"$ROOT_DIR/recommendations/recommend_from_interests.sh" > "$work_dir/interests.txt" &
interests_pid=$!
"$UI" progress running "Interest agent is matching your goals"

"$ROOT_DIR/recommendations/recommend_for_discovery.sh" > "$work_dir/discovery.txt" &
discovery_pid=$!
"$UI" progress running "Discovery agent is looking beyond the familiar"

wait "$history_pid"
"$UI" progress done "History agent finished"
wait "$interests_pid"
"$UI" progress done "Interest agent finished"
wait "$discovery_pid"
"$UI" progress done "Discovery agent finished"

# This is the central composition pipeline: combine -> refine -> shortlist.
cat "$work_dir/history.txt" "$work_dir/interests.txt" "$work_dir/discovery.txt" \
  | "$ROOT_DIR/recommendations/refine_recommendations.sh" \
  > "$work_dir/final.txt"

if [ ! -s "$work_dir/final.txt" ]; then
  echo "No new recommendations were available."
  exit 0
fi

"$UI" show "$work_dir/final.txt"

if [ "${1:-}" != "--non-interactive" ] && [ -t 0 ]; then
  selected="$("$UI" choose "$work_dir/final.txt")"
  if [ -n "$selected" ]; then
    IFS='|' read -r score title author genre year strategy reason link <<EOF
$selected
EOF
    "$ROOT_DIR/workflows/manage_library.sh" add-recommendation \
      "$title" "$author" "$genre" "$year" "$strategy" "$reason" "$link"
  fi
fi
