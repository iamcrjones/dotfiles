#!/bin/zsh
# Opens unread PR review reports and marks them read (moves them to reports/read/).
REPORTS="$HOME/.claude/pr-review-watcher/reports"
mkdir -p "$REPORTS/read"
reports=("$REPORTS"/*.md(N))
(( ${#reports} )) || { echo "No unread PR reviews."; exit 0; }
for f in $reports; do
  echo "$(head -1 "$f" | sed 's/^# //')"
  open "$f"
  mv "$f" "$REPORTS/read/"
done
