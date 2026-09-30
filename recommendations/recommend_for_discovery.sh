#!/usr/bin/env bash

# Deliberately choose exploratory books outside the profile's usual subjects.
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
delay="${BOOK_MANAGER_AGENT_DELAY:-1}"
sleep "$delay"

awk -F'|' '
  BEGIN { rank=0 }
  $0 !~ /^#/ && index(tolower($5), "discovery") > 0 {
    score=91-rank
    printf "%d|%s|%s|%s|%s|discovery|A deliberate stretch beyond your usual reading pattern|%s\n", score,$1,$2,$3,$4,$6
    rank++
    if (rank == 5) exit
  }
' "$ROOT_DIR/data/book_catalog.txt"
