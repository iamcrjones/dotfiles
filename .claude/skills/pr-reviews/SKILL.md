---
name: pr-reviews
description: Start, stop or check the background PR review watcher, and list unread four-pass PR review reports and reply follow-ups from the background PR review watcher, let the user pick one to view, and mark it read on request. Use when the user asks about their PR reviews, unread reviews, review findings, or says "check my reviews" / "what did the reviewer find", or wants to start or stop the PR review watcher.
---

# Unread PR Reviews

A launchd job runs `scripts/run.sh` (in this skill's folder) every 5 minutes. It writes two kinds of report:
- **Review reports** (`<repo>-<n>-<sha>.md`, contain `## Code Review Summary`): a four-pass review, written when the user is a requested reviewer or assignee and a new head commit appears, or when a PR the user reviewed or commented on gets commits newer than their last GitHub review (or last comment).
- **Reply follow-ups** (`<repo>-<n>-replies-<date>.md`, contain `## Reply Follow-up`): written when someone replies to the user's review threads, or the PR author replies after their general comment. Each thread gets a verdict: Resolved in code, Answered, no change needed, Not resolved, or Needs your response. The `Thread data` block at the end has each thread's `reply_to_id` and URL.

Line 3 of every report is `Trigger: ...`, saying why it was written. Unread reports sit directly in `~/.claude/pr-review-watcher/reports/*.md`; read ones live in `reports/read/`. The status line counts the unread ones. Runtime data (reports, `reviewed.txt`, repo clones, `watcher.log`) lives in `~/.claude/pr-review-watcher/`, outside the dotfiles repo.

## Starting and stopping the watcher

Use this section when the user asks to install, start, stop, pause or check the watcher, instead of the review steps below. The launchd label is `com.iamcrjones.pr-review-watcher`; `scripts/install.sh` generates the plist at `~/Library/LaunchAgents/com.iamcrjones.pr-review-watcher.plist`.

- **Install or start** (also how to set it up on a new machine): run `scripts/install.sh` from this skill's folder (`~/.claude/skills/pr-reviews/scripts/install.sh`). It checks that `claude`, `gh` (logged in), `git`, `jq` and the `/review` command are present, writes the plist with this machine's PATH, and starts the job. It's safe to re-run. The first check runs straight away, then every 5 minutes. `PR_WATCHER_INTERVAL=<seconds>` changes the interval.
- **Stop** (stays off after logout or reboot):
  ```
  launchctl bootout gui/$(id -u)/com.iamcrjones.pr-review-watcher
  launchctl disable gui/$(id -u)/com.iamcrjones.pr-review-watcher
  ```
  A review already in progress finishes on its own; `~/.claude/pr-review-watcher/.lock` exists while one is running. To restart, run `scripts/install.sh` again.
- **Uninstall:** `scripts/install.sh --uninstall` stops the job and removes the plist; reports are kept.
- **Status:** `launchctl print gui/$(id -u)/com.iamcrjones.pr-review-watcher` (an error means it isn't running), plus `tail ~/.claude/pr-review-watcher/watcher.log`.

Confirm the result to the user after starting or stopping.

## Steps

1. **List.** Find unread reports with `ls ~/.claude/pr-review-watcher/reports/*.md`. If there are none, say so and stop. For each, read only the first three lines (title, PR URL, trigger) and the counts: for review reports, the items under `### Critical Issues` and `### Warnings`; for reply follow-ups, the verdicts. Show a numbered list: PR title, repo#number, the report type with its trigger (e.g. "re-review: new commits since your last review"), and either "N critical, N warnings" or "N replies: N need you, N resolved". Don't summarise the findings yet.
2. **Ask which to view.** Use AskUserQuestion to ask which one they'd like to view first, one option per report (up to 4; if there are more, list them in the question and let the user answer with Other). If there's only one, still ask, so they can decline.
3. **View.** Read that report in full, including the four per-pass reports in the `<details>` blocks, and present:
   - **Heading** with the PR title, linked to the PR URL. If the PR has new commits since the report's head SHA (`gh pr view <n> -R <repo> --json headRefOid`), say the review may be stale.
   - **Summary:** the overall assessment from the report, as written or lightly trimmed.
   - **Action now:** everything that should be fixed or answered before the PR is approved: all critical issues, plus warnings that are real defects, risks or unverified assumptions that could break things. One line per item with file:line, which passes flagged it, and the concrete fix or question for the author.
   - **Nice to have:** everything that could be done in this PR or a follow-up but shouldn't block approval: style, naming, docs, comments, optional hardening, out-of-scope ideas. One line per item.
   - **Conflicts:** any disagreements between passes, and any finding the report itself marked as overstated, with your call on which side is right.

   For a **reply follow-up**, present instead:
   - **Heading** with the PR title and link, and the trigger
   - **Needs you:** threads marked Not resolved or Needs your response. One item per thread: path:line, the thread link, a one-line gist of your comment and the reply, the verdict and the suggested next step.
   - **Done:** threads marked Resolved in code or Answered, no change needed, one line each with the evidence.

   In the steps below, "Action now items" for a reply follow-up means the Needs you threads. Validation also re-checks any Resolved in code verdict before the user relies on it.

   Merge duplicates across the four passes into one item. Classify by impact, not by the label a pass gave it: a NOTE that hides a real bug goes under Action now, and a WARNING that's purely stylistic goes under Nice to have. Drop nothing; if an item doesn't fit either list, put it under Nice to have.
4. **Offer to validate.** Use AskUserQuestion to ask whether they want to investigate further to validate the Action now items. On no, skip to step 7.
5. **Validate.** Make a throwaway worktree at the report's head SHA so the background watcher can't move the checkout underneath you:
   ```
   repo_dir=~/.claude/pr-review-watcher/repos/<owner>/<repo>
   git -C "$repo_dir" fetch --quiet origin "+pull/<n>/head:refs/pr/<n>"
   git -C "$repo_dir" worktree add --detach "$TMPDIR/pr-<n>-validate" <head sha>
   ```
   **Install dependencies** in the worktree so type checks and tests can run. Pick the installer from the lockfile at the worktree root (and in any app/package subfolder the Action now items point at), always with a frozen lockfile and with install scripts disabled, because the code being installed comes from someone else's PR:

   | Lockfile | Command |
   |---|---|
   | `pnpm-lock.yaml` | `pnpm install --frozen-lockfile --ignore-scripts` |
   | `yarn.lock` (Yarn 1) | `yarn install --frozen-lockfile --ignore-scripts` |
   | `yarn.lock` + `.yarnrc.yml` (Yarn 2+) | `yarn install --immutable --mode=skip-build` |
   | `package-lock.json` | `npm ci --ignore-scripts` |
   | `bun.lock` / `bun.lockb` | `bun install --frozen-lockfile --ignore-scripts` |
   | `composer.lock` | `composer install --no-scripts --no-interaction --prefer-dist` |

   Before installing, check whether the PR changes dependencies: `git -C <worktree> diff --name-only origin/<base>...HEAD | grep -E '(^|/)(package\.json|composer\.json|pnpm-lock\.yaml|yarn\.lock|package-lock\.json|bun\.lockb?|composer\.lock|\.npmrc|\.yarnrc\.yml)$'`. If it does, show the user which files changed and the added or changed packages, and use AskUserQuestion to ask whether to install before running anything. Never drop the frozen-lockfile or no-scripts flags; if the install fails without scripts, or the lockfile is out of date, don't work around it. Tell the user, carry on validating without installed dependencies (read the code instead of running it), and note it next to any verdict that would have needed a run.

   **All validation must be local only.** The fetch and the dependency install above are the last network calls until step 6. While validating, only read files in the worktree and run commands that stay on this machine (grep, `git log`, `git blame`, `git diff`, the repo's type check or unit tests run offline). Never:
   - call GitHub (`gh`, `gh api`, the GitHub web UI) or any other remote service, API, MCP connector or URL (`curl`, WebFetch, WebSearch)
   - trigger workflows, deployments or CI runs, or push, open or update anything remote
   - run tests or scripts that hit real external services, or that need secrets or credentials
   - install, add or update packages beyond the one setup install above

   If an item can only be settled with remote information (repo settings, secrets, App permissions, CI results, third-party docs), don't go and look. Mark it Unclear and say what the author would need to confirm.

   For each Action now item, check the claim against the actual code: read the cited lines and their callers, configs and tests, and run local commands where they settle it. For more than two items, spawn one subagent per item in parallel, each given the worktree path, the finding, the relevant per-pass report text and the local-only rules above, verbatim. Give each item a verdict:
   - **Confirmed:** the problem is real. Cite the evidence (file:line, command output).
   - **Refuted:** the code already handles it. Say where.
   - **Unclear:** can't be settled from the code (e.g. depends on repo settings or secrets). Say what the author would need to confirm.

   **Engineering standards.** If this machine has an engineering standards config, the check must also cover those standards. The config lives outside the dotfiles repo at `~/.claude/pr-review-watcher/standards.json`:
   ```json
   {
     "plugin": "<plugin>@<marketplace>",
     "root": "<folder inside the plugin>",
     "standards": [
       { "file": "<path under root>", "applies_to": "always" },
       { "file": "<path under root>", "applies_to": "<kind of change, e.g. backend PHP>" }
     ]
   }
   ```
   Resolve it locally:
   ```
   cfg=~/.claude/pr-review-watcher/standards.json
   plugin=$(jq -r '.plugin' "$cfg" 2>/dev/null)
   base=$(jq -r --arg p "$plugin" '.plugins[$p][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
   [ -n "$base" ] && [ -d "$base/$(jq -r '.root' "$cfg")" ] && echo "$base/$(jq -r '.root' "$cfg")"
   ```
   If it prints a path, read each listed file from it whose `applies_to` is `always` or matches what the diff touches. These are local files, so this stays within the local-only rule.

   Then:
   - Check each Action now item against them too, and cite the standard in its verdict when one applies (e.g. "also breaks coding standards: KISS (Must)").
   - Check the PR's diff (`git diff origin/<base>...HEAD` in the worktree) for violations the four passes missed. Add each as a new item tagged **Standards**, with the rule, its severity and file:line. Violations of blocking rules (e.g. **Must**) are Confirmed Action now items and go on to step 6; softer ones (e.g. **Should**, **Prefer**) go under Nice to have and aren't drafted unless the user asks.
   - If a standard covers PR shape (size, scope, PR body template), check that too. The PR body and its size (+/- lines, file count) are in the `PR description` block at the end of the report. Older reports don't have it; then mark the item Unclear rather than fetching it.
   - When validating in parallel, give each subagent the resolved standards path and the list of files to read.

   If there's no config, or its plugin isn't installed, skip this and say "No engineering standards configured, not checked" above the verdicts.

   Present the verdicts as a list, then remove the worktree: `git -C "$repo_dir" worktree remove --force "$TMPDIR/pr-<n>-validate"`.
6. **Draft comments.** Draft one PR comment per Confirmed or Unclear item; drop Refuted items. Each draft shows its target (`path:line` on the PR's new side, or "general comment" if the line isn't in the diff) and a body that:
   - **starts with a casual one-line disclaimer** saying the comment came from the user's review assistant, ending with a robot emoji, then a blank line before the comment itself. E.g. "Heads up, this one came from my review assistant 🤖". Every comment needs it, including general comments; vary the wording a little between comments so it doesn't read as boilerplate, but always keep it one sentence with 🤖 at the end.
   - sounds like a friendly teammate, not a formal audit: casual, first person, contractions, plain words. E.g. "Hey, I think this'll grab every permission the App has. Could we scope it to just `pull-requests: write`?" rather than "The token is not scoped and therefore inherits all App permissions."
   - says the problem in one or two short sentences, with no headings, severity labels or rule IDs. Mention a standard only in passing ("our coding standards lean towards…").
   - softens with "I think", "might", "could we", but stays clear about what needs to change on Action now items
   - apart from the disclaimer, doesn't mention passes, reports, validation or AI
   - for Unclear items, asks the author a genuine question ("Is the App already installed on this repo? Couldn't tell from the code.") rather than asserting a bug
   - no other emoji (only the disclaimer's 🤖) and no exclamation-mark pile-ups; one "nice" or "thanks" is fine where it fits
   - includes a small code suggestion when the fix is a few lines: a GitHub ```` ```suggestion ```` block replacing the exact commented line(s) when the line is in the diff, otherwise a normal fenced snippet

      For a **reply follow-up**, each draft is a reply in the existing thread instead: target is the thread (its `reply_to_id` from the Thread data block) or, for a general comment, the PR conversation. Same tone and disclaimer rules. A reply can also just say thanks and confirm it's sorted, if the user wants to close the loop on Done threads.

   Number the drafts. Then use AskUserQuestion (multiSelect) to ask which, if any, to submit. Always include a **"No comments needed"** option, listed first, plus one option per draft. AskUserQuestion allows 4 options, so with more than 3 drafts, list them all in the question text and offer "No comments needed", "Submit all" and let them pick specific numbers or edit wording via Other. If they choose "No comments needed" (alone or together with drafts), post nothing and go to step 7. Otherwise post only the chosen ones, as a single review with `event: "COMMENT"` (never APPROVE or REQUEST_CHANGES): write the payload to a JSON file in the scratchpad (`commit_id` = head SHA, `comments` = `[{path, line, side: "RIGHT", body}]`, general comments joined into the review `body`) and run `gh api repos/<owner>/<repo>/pulls/<n>/reviews --method POST --input <file>`. Show the review URL from the response. For reply follow-up drafts, post each chosen one separately: thread replies with `gh api repos/<owner>/<repo>/pulls/<n>/comments/<reply_to_id>/replies --method POST -f body=<body>`, general replies with `gh api repos/<owner>/<repo>/issues/<n>/comments --method POST -f body=<body>`. Show each comment's `html_url`. If the head SHA has moved since the report, warn before posting, since line numbers may be off.
7. **Ask to mark read.** Use AskUserQuestion to ask specifically whether to mark this report as read. Only on yes: `mkdir -p ~/.claude/pr-review-watcher/reports/read && mv <file> ~/.claude/pr-review-watcher/reports/read/`. Then tell the user the unread count in the status line is cleared for **all** Claude Code sessions on this Mac, not just this one: every session counts the same `reports/` folder, so others update the next time their status line refreshes (their next message). On no, leave it where it is; it stays counted as unread in every session.
8. **Next.** If unread reports remain, ask whether they want to view another and go back to step 3.

## Rules

- Never mark a report read without an explicit yes for that report.
- Never post anything to GitHub except the specific comments the user selected in step 6. Never approve or request changes.
- Validation is local only and read-only: apart from the setup fetch and frozen, no-scripts dependency install, no network calls, remote services or connectors, and no edits, commits or pushes in the worktree. Anything that needs remote information is marked Unclear, not looked up.
- Every comment posted to GitHub starts with the review-assistant disclaimer ending in 🤖, including ones the user reworded. If their edit dropped it, add it back.
