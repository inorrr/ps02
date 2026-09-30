#!/usr/bin/env bash

# Recommend catalog books in genres the reader has rated or saved.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
delay="${BOOK_MANAGER_AGENT_DELAY:-1}"
sleep "$delay"

genre_weights="$("$ROOT_DIR/data/book_database.sh" list | awk -F'|' '
  {
    weight=1
    if ($6 == "finished") weight+=2
    if ($7+0 >= 4) weight+=($7+0)-2
    score[$4]+=weight
  }
  END { for (genre in score) print genre "|" score[genre] }
')"

if [ -z "$genre_weights" ]; then
  genre_weights="Technology|2
Systems|2"
fi

printf '%s\n' "$genre_weights" | awk -F'|' -v catalog="$ROOT_DIR/data/book_catalog.txt" '
  { weight[tolower($1)]=$2 }
  END {
    while ((getline line < catalog) > 0) {
      if (line ~ /^#/) continue
      split(line, b, "|")
      genre=tolower(b[3])
      if (weight[genre] > 0) {
        score=82 + weight[genre]
        if (score > 98) score=98
        printf "%d|%s|%s|%s|%s|history|Because %s is prominent in your library|%s\n", score,b[1],b[2],b[3],b[4],b[3],b[6]
      }
    }
    close(catalog)
  }
' | sort -t'|' -k1,1nr | head -n 5
