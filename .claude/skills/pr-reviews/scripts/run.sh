#!/bin/zsh
# Polls GitHub for open PRs I'm involved in and writes local reports. Never posts to GitHub.
#   - requested reviewer / assignee: four-pass /review on each new head commit
#   - reviewed or commented by me: four-pass /review again once there are commits newer
#     than my last GitHub review (or my last comment, if I never submitted a review)
#   - someone replied to my comments: a reply follow-up report
# DRY_RUN=1 prints what it would do without cloning or running Claude.
set -u
# launchd passes the PATH captured by install.sh; fall back to Homebrew + system dirs
export PATH="${PATH:-/usr/bin:/bin}:/opt/homebrew/bin:/usr/local/bin"

ROOT="$HOME/.claude/pr-review-watcher"
REPOS="$ROOT/repos"
REPORTS="$ROOT/reports"
STATE="$ROOT/reviewed.txt"   # lines: owner/repo#number@headSha
REPLIES="$ROOT/replied.txt"  # lines: GitHub node id of each reply already reported
LOCK="$ROOT/.lock"
DRY_RUN="${DRY_RUN:-}"
# Ignore commits and replies older than this, so old PRs don't flood in
CUTOFF=$(date -u -v-"${PR_WATCHER_MAX_AGE_DAYS:-14}"d +%Y-%m-%dT%H:%M:%SZ)
mkdir -p "$REPOS" "$REPORTS"; touch "$STATE" "$REPLIES"

# Skip if a previous run is still reviewing
mkdir "$LOCK" 2>/dev/null || { echo "$(date) previous run still active"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

notify() {
  [[ -n "$DRY_RUN" ]] && { echo "  notify: $1 — $2"; return; }
  osascript -e "display notification \"$2\" with title \"PR Review\" subtitle \"$1\" sound name \"Glass\""
}

CLAUDE_TOOLS=(--model claude-opus-5-5
  --allowedTools "Read" "Grep" "Glob" "Agent"
    "Bash(git diff:*)" "Bash(git log:*)" "Bash(git show:*)" "Bash(git branch:*)" "Bash(git status:*)"
  --disallowedTools "Bash(gh:*)" "Bash(git push:*)" "Bash(curl:*)" "mcp__*" "WebFetch" "WebSearch")

me=$(gh api user --jq .login) || exit 0

# PR candidates as "repo number direct", where direct=true means requested/assigned
prs=$( { for q in --review-requested=@me --assignee=@me --reviewed-by=@me --commenter=@me; do
           gh search prs $q --state=open --json repository,number,author --limit 50 \
             | jq -c --arg q "$q" '.[] | {r: .repository.nameWithOwner, n: .number, a: .author.login,
                                          d: ($q == "--review-requested=@me" or $q == "--assignee=@me")}'
         done; } \
       | jq -rs --arg me "$me" 'group_by([.r, .n]) | map({r: .[0].r, n: .[0].n, a: .[0].a, d: (map(.d) | any)})
                                | .[] | select(.d or .a != $me) | "\(.r) \(.n) \(.d)"' )

QUERY='query($owner: String!, $name: String!, $num: Int!, $me: String!) {
  repository(owner: $owner, name: $name) { pullRequest(number: $num) {
    title body isDraft headRefOid baseRefName additions deletions changedFiles
    author { login }
    commits(last: 1) { nodes { commit { committedDate } } }
    reviews(last: 1, author: $me) { nodes { commit { oid } submittedAt body } }
    comments(last: 100) { nodes { id url body createdAt author { __typename login } } }
    reviewThreads(first: 100) { nodes { isResolved path line
      comments(first: 50) { nodes { id databaseId url body createdAt author { __typename login } } } } }
  } } }'

# Clone/fetch the PR into $REPOS/<repo> and check out its head. Prints the dir.
checkout_pr() {
  local repo=$1 num=$2 base=$3 sha=$4 dir="$REPOS/$1"
  # HTTPS via gh's credential helper: the SSH agent (1Password) can't approve while the Mac is locked
  [[ -d "$dir/.git" ]] || git clone --quiet "https://github.com/$repo.git" "$dir" </dev/null || return 1
  git -C "$dir" remote set-url origin "https://github.com/$repo.git"
  git -C "$dir" fetch --quiet --force origin "+refs/heads/${base}:refs/remotes/origin/${base}" "+pull/${num}/head:refs/pr/${num}" </dev/null || return 1
  git -C "$dir" checkout --quiet --force --detach "refs/pr/$num" || return 1
  [[ $(git -C "$dir" rev-parse HEAD) == "$sha" ]] || { notify "$repo#$num" "Checkout mismatch — see watcher.log"; return 1; }
  git -C "$dir" clean -fdq
  echo "$dir"
}

while read -r repo num direct; do
  [[ -z "$repo" ]] && continue
  pr=$(gh api graphql -f query="$QUERY" -F owner="${repo%/*}" -F name="${repo#*/}" -F num="$num" -f me="$me" \
         --jq .data.repository.pullRequest) || continue
  [[ -z "$pr" || "$pr" == null ]] && continue
  [[ $(jq -r .isDraft <<<"$pr") == true ]] && continue
  sha=$(jq -r .headRefOid <<<"$pr"); base=$(jq -r .baseRefName <<<"$pr"); title=$(jq -r .title <<<"$pr")
  link="https://github.com/$repo/pull/$num"

  # ── Full review: requested/assigned, or new commits since my last review/comment ──
  trigger=""
  if [[ "$direct" == true ]]; then
    trigger="review requested or assigned"
  else
    head_date=$(jq -r '.commits.nodes[0].commit.committedDate' <<<"$pr")
    last_review_sha=$(jq -r '.reviews.nodes[0].commit.oid // empty' <<<"$pr")
    last_comment=$(jq -r --arg me "$me" '[.comments.nodes[], .reviewThreads.nodes[].comments.nodes[]
                     | select(.author.login == $me) | .createdAt] | max // empty' <<<"$pr")
    if [[ "$head_date" > "$CUTOFF" ]]; then
      if [[ -n "$last_review_sha" ]]; then
        [[ "$last_review_sha" != "$sha" ]] && trigger="new commits since your last review on ${last_review_sha:0:7}"
      elif [[ -n "$last_comment" && "$head_date" > "$last_comment" ]]; then
        trigger="new commits since your last comment"
      fi
    fi
  fi
  key="$repo#$num@$sha"
  grep -qxF "$key" "$STATE" && trigger=""

  if [[ -n "$trigger" ]]; then
    echo "$(date) reviewing $key ($trigger)"
    if [[ -z "$DRY_RUN" ]] && dir=$(checkout_pr "$repo" "$num" "$base" "$sha"); then
      report="$REPORTS/${repo//\//-}-$num-${sha:0:7}.md"
      ( cd "$dir" && claude -p "/review origin/$base...HEAD" "${CLAUDE_TOOLS[@]}" </dev/null ) > "$report" 2>>"$ROOT/watcher.log"

      if grep -q "^## Code Review Summary" "$report"; then
        { echo "# $repo#$num — $title"; echo "$link · head ${sha:0:7}"; echo "Trigger: $trigger"; echo
          cat "$report"; echo
          echo "<details>"; echo "<summary>PR description ($(jq -r '"+\(.additions)/-\(.deletions), \(.changedFiles) files"' <<<"$pr"))</summary>"; echo
          jq -r '.body // "(empty)"' <<<"$pr"; echo; echo "</details>"; } > "$report.tmp" && mv "$report.tmp" "$report"
        crit=$(awk '/^### Critical/{f=1;next}/^### /{f=0}f&&/^[-*0-9]/' "$report" | wc -l | tr -d ' ')
        warn=$(awk '/^### Warnings/{f=1;next}/^### /{f=0}f&&/^[-*0-9]/' "$report" | wc -l | tr -d ' ')
        echo "$key" >> "$STATE"
        notify "$repo#$num" "$crit critical, $warn warnings — $title"
      else
        notify "$repo#$num" "Review failed — see watcher.log"
      fi
    fi
  fi

  # ── Reply follow-up: new human replies to my review threads or general comments ──
  threads=$(jq -c --arg me "$me" --arg cutoff "$CUTOFF" '
    . as $pr
    | def human: .author != null and .author.__typename != "Bot" and .author.login != $me;
    def fresh($after): select(human and .createdAt > $after and .createdAt > $cutoff);
    [ $pr.reviewThreads.nodes[]
      | . as $t
      | ($t.comments.nodes | map(select(.author.login == $me)) | last) as $mine
      | select($mine != null)
      | ($t.comments.nodes | map(fresh($mine.createdAt))) as $new
      | select($new | length > 0)
      | {kind: "thread", path: $t.path, line: $t.line, resolved: $t.isResolved,
         reply_to_id: $t.comments.nodes[0].databaseId, url: $t.comments.nodes[0].url,
         mine: $mine.body, replies: ($new | map({id, author: .author.login, body, createdAt}))} ]
    + ( ([$pr.comments.nodes[] | select(.author.login == $me)] | last) as $mine
        | if $mine == null then [] else
            [ $pr.comments.nodes
              | map(fresh($mine.createdAt) | select(.author.login == $pr.author.login or (.body | test("@" + $me; "i"))))
              | select(length > 0)
              | {kind: "general", url: $mine.url, mine: $mine.body,
                 replies: map({id, author: .author.login, body, createdAt})} ]
          end )' <<<"$pr")
  new_ids=$(jq -r '.[].replies[].id' <<<"$threads" | grep -vxFf "$REPLIES")
  [[ -z "$new_ids" ]] && continue
  # Keep only threads that have at least one unreported reply
  threads=$(jq -c --argjson ids "$(jq -R . <<<"$new_ids" | jq -s .)" 'map(select(any(.replies[]; .id as $i | $ids | index($i))))' <<<"$threads")
  count=$(wc -l <<<"$new_ids" | tr -d ' ')

  echo "$(date) reply follow-up $repo#$num ($count new)"
  [[ -n "$DRY_RUN" ]] && { jq -r '.[] | "  \(.kind) \(.path // "") \(.url)"' <<<"$threads"; continue; }
  dir=$(checkout_pr "$repo" "$num" "$base" "$sha") || continue

  report="$REPORTS/${repo//\//-}-$num-replies-$(date +%Y%m%d-%H%M).md"
  prompt="You're following up on review comments I (@$me) left on $repo#$num (\"$title\"). People have replied since. The PR head ($sha) is checked out in the current directory.

Work locally only: read files and use git commands. Don't contact GitHub or any other service, and don't change any files.

For each thread in the JSON below, read my comment, the replies, and the current code at the cited path, then give one verdict:
- Resolved in code: the code now addresses my comment (cite file:line)
- Answered, no change needed: the reply explains convincingly why no change is needed
- Not resolved: the reply or code doesn't address it (say what's still missing)
- Needs your response: they asked me a question or want my decision

Output markdown that starts with the exact heading '## Reply Follow-up'. Then one '### ' section per thread, titled with path:line (or 'General comment'), containing: the thread link, my comment (quoted, trimmed to its point), each reply as 'author: text', **Verdict:**, **Evidence:** and **Suggested next step:**. End with a one-line tally of verdicts.

Threads:
$threads"
  ( cd "$dir" && claude -p "$prompt" "${CLAUDE_TOOLS[@]}" </dev/null ) > "$report" 2>>"$ROOT/watcher.log"

  if grep -q "^## Reply Follow-up" "$report"; then
    { echo "# $repo#$num — $title"; echo "$link · head ${sha:0:7}"; echo "Trigger: $count new repl$([[ $count == 1 ]] && echo y || echo ies) to your comments"; echo
      cat "$report"; echo
      echo "<details>"; echo "<summary>Thread data (for replying)</summary>"; echo; echo '```json'
      jq '.' <<<"$threads"; echo '```'; echo "</details>"; } > "$report.tmp" && mv "$report.tmp" "$report"
    print -r -- "$new_ids" >> "$REPLIES"
    notify "$repo#$num" "$count new repl$([[ $count == 1 ]] && echo y || echo ies) to your comments — $title"
  else
    notify "$repo#$num" "Reply follow-up failed — see watcher.log"
  fi
done <<<"$prs"
