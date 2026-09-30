#!/usr/bin/env bash

# Recommend books whose catalog topics match the editable interest profile.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INTERESTS_FILE="${BOOK_MANAGER_INTERESTS:-$ROOT_DIR/data/interests.txt}"
delay="${BOOK_MANAGER_AGENT_DELAY:-1}"
sleep "$delay"

awk -F'|' -v interests_file="$INTERESTS_FILE" '
  BEGIN {
    while ((getline interest < interests_file) > 0) {
      if (interest != "" && interest !~ /^#/) interests[++count]=tolower(interest)
    }
    close(interests_file)
  }
  $0 !~ /^#/ {
    topics=tolower($5)
    matches=0
    matched=""
    for (i=1; i<=count; i++) {
      if (index(topics, interests[i]) > 0) {
        matches++
        if (matched == "") matched=interests[i]
        else matched=matched ", " interests[i]
      }
    }
    if (matches > 0) {
      score=84 + (matches * 4)
      if (index(topics, "interior design") > 0) score+=3
      if (index(topics, "romance") > 0) score+=2
      if (index(topics, "mystery") > 0) score+=1
      printf "%d|%s|%s|%s|%s|interests|Matches your interests: %s|%s\n", score,$1,$2,$3,$4,matched,$6
    }
  }
' "$ROOT_DIR/data/book_catalog.txt" | sort -t'|' -k1,1nr | head -n 12
