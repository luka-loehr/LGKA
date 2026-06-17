#!/usr/bin/env bash
set -euo pipefail

LCOV_FILE="coverage/lcov.info"
MIN_COVERAGE="${1:-7}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Coverage file not found: $LCOV_FILE"
  echo "Run: flutter test --coverage"
  exit 1
fi

line_stats=$(awk -F: '
  /^LF:/ { total += $2 }
  /^LH:/ { hit += $2 }
  END {
    if (total == 0) {
      print "0 0 0"
    } else {
      pct = (hit / total) * 100
      printf "%.2f %d %d\n", pct, hit, total
    }
  }
' "$LCOV_FILE")

line_pct=$(echo "$line_stats" | awk '{print $1}')
hit_lines=$(echo "$line_stats" | awk '{print $2}')
total_lines=$(echo "$line_stats" | awk '{print $3}')

if awk -v current="$line_pct" -v min="$MIN_COVERAGE" 'BEGIN { exit (current + 0 >= min + 0) ? 0 : 1 }'; then
  echo "Coverage gate passed: ${line_pct}% (${hit_lines}/${total_lines}) >= ${MIN_COVERAGE}%"
else
  echo "Coverage gate failed: ${line_pct}% (${hit_lines}/${total_lines}) < ${MIN_COVERAGE}%"
  exit 1
fi
