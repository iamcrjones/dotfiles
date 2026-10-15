#!/bin/zsh
# Polls GitHub for open PRs where I'm a requested reviewer or assignee, runs the
# four-pass /review on each new head commit, and notifies locally. Never posts to GitHub.
set -u
# launchd passes the PATH captured by install.sh; fall back to Homebrew + system dirs
export PATH="${PATH:-/usr/bin:/bin}:/opt/homebrew/bin:/usr/local/bin"

ROOT="$HOME/.claude/pr-review-watcher"
REPOS="$ROOT/repos"
REPORTS="$ROOT/reports"
STATE="$ROOT/reviewed.txt"   # lines: owner/repo#number@headSha
LOCK="$ROOT/.lock"
mkdir -p "$REPOS" "$REPORTS"; touch "$STATE"

# Skip if a previous run is still reviewing
mkdir "$LOCK" 2>/dev/null || { echo "$(date) previous run still active"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

notify() { osascript -e "display notification \"$2\" with title \"PR Review\" subtitle \"$1\" sound name \"Glass\""; }

prs=$( { gh search prs --review-requested=@me --state=open --json repository,number --limit 50
         gh search prs --assignee=@me         --state=open --json repository,number --limit 50; } \
       | jq -rs 'add | map("\(.repository.nameWithOwner) \(.number)") | unique | .[]' )

echo "$prs" | while read -r repo num; do
  [[ -z "$repo" ]] && continue
  meta=$(gh pr view "$num" -R "$repo" --json headRefOid,baseRefName,title,isDraft,body,additions,deletions,changedFiles) || continue
  [[ $(jq -r .isDraft <<<"$meta") == true ]] && continue
  sha=$(jq -r .headRefOid <<<"$meta"); base=$(jq -r .baseRefName <<<"$meta"); title=$(jq -r .title <<<"$meta")
  key="$repo#$num@$sha"
  grep -qxF "$key" "$STATE" && continue

  echo "$(date) reviewing $key"
  dir="$REPOS/$repo"
  [[ -d "$dir/.git" ]] || gh repo clone "$repo" "$dir" -- --quiet || continue
  git -C "$dir" fetch --quiet --force origin "+refs/heads/${base}:refs/remotes/origin/${base}" "+pull/${num}/head:refs/pr/${num}" || continue
  git -C "$dir" checkout --quiet --force --detach "refs/pr/$num"
  [[ $(git -C "$dir" rev-parse HEAD) == "$sha" ]] || { notify "$repo#$num" "Checkout mismatch — see watcher.log"; continue; }
  git -C "$dir" clean -fdq

  report="$REPORTS/${repo//\//-}-$num-${sha:0:7}.md"
  ( cd "$dir" && claude -p "/review origin/$base...HEAD" \
      --model claude-opus-5-5 \
      --allowedTools "Read" "Grep" "Glob" "Agent" \
        "Bash(git diff:*)" "Bash(git log:*)" "Bash(git show:*)" "Bash(git branch:*)" "Bash(git status:*)" \
      --disallowedTools "Bash(gh:*)" "Bash(git push:*)" "Bash(curl:*)" "mcp__*" \
  ) > "$report" 2>>"$ROOT/watcher.log"

  if grep -q "^## Code Review Summary" "$report"; then
    { echo "# $repo#$num — $title"; echo "https://github.com/$repo/pull/$num · head ${sha:0:7}"; echo
      cat "$report"; echo
      echo "<details>"; echo "<summary>PR description ($(jq -r '"+\(.additions)/-\(.deletions), \(.changedFiles) files"' <<<"$meta"))</summary>"; echo
      jq -r '.body // "(empty)"' <<<"$meta"; echo; echo "</details>"; } > "$report.tmp" && mv "$report.tmp" "$report"
    crit=$(awk '/^### Critical/{f=1;next}/^### /{f=0}f&&/^[-*0-9]/' "$report" | wc -l | tr -d ' ')
    warn=$(awk '/^### Warnings/{f=1;next}/^### /{f=0}f&&/^[-*0-9]/' "$report" | wc -l | tr -d ' ')
    echo "$key" >> "$STATE"
    notify "$repo#$num" "$crit critical, $warn warnings — $title"
  else
    notify "$repo#$num" "Review failed — see watcher.log"
  fi
done
