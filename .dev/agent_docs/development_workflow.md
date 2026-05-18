# Development Workflow

## Issue Tracking & Code Hosting

- Issues (bugs, stories, epics) are tracked on **GitHub** — in `zammad/zammad`
  (public) and private repositories (e.g. `zammad/coordination-desktop-view`).
- Code is developed on a **self-hosted GitLab** instance.
- GitHub hosts a **read-only mirror** — synced automatically when public branches
  like `develop` or `stable` are updated.
- Branches prefixed with `private/` are **never synced** to GitHub.

All branches must start with `private/` to prevent unintended syncing.

## Tools

- **GitHub MCP server** — for reading issues, labels, and comments.
- **`glab` CLI** — for pushing branches, creating merge requests, and other
  GitLab operations. Authenticated against the self-hosted GitLab instance.

## Lifecycle

### 1. Understand

Read the GitHub issue thoroughly before writing any code. Clarify scope,
acceptance criteria, and edge cases. If the issue is ambiguous, ask the user
for clarification rather than guessing.

**Determine the mode.** If the user supplied `--parent <github_issue_url>`,
this is **attach mode**: the task is part of a larger story whose branch and
MR already exist. Otherwise, this is **standalone mode**: the task gets its
own branch and MR. The parent may live in a different repository — parse
owner + repo + number from the URL, do not assume same-repo.

In attach mode, also:

- Read the parent issue via the GitHub MCP server (it provides context the
  task issue alone doesn't have).
- List the parent's sub-issues. Note which are already closed, which are
  in progress, and who is assigned — this prevents stepping on a colleague's
  work.
- Confirm the existing branch is already checked out in the current workspace
  (Conductor creates the workspace from a branch; the branch is on disk
  before the workflow starts). If it is not — abort and ask the user.

Then determine **which parts of the codebase the issue affects**:

- Check labels and comments for scope hints (when available).
- Otherwise, search the codebase for keywords from the issue title and body
  to locate the relevant component(s).
- Identify which stack is affected: CoffeeScript frontend, Vue 3 frontend
  (desktop or mobile), REST backend, GraphQL layer, services, etc.
- State your conclusion explicitly before moving on, e.g.
  "This issue affects the CoffeeScript frontend (KB answers component) and
  the REST controller behind it. I will NOT investigate Vue 3, GraphQL, or
  unrelated services unless something during research requires it."

This explicit scoping prevents broad codebase exploration in areas the
issue does not touch.

### 2. Research

Investigate only the parts of the codebase identified in the Understand
phase. Delegate broad research to separate agents to keep your main context
clean. Understand the existing patterns before introducing new ones.

If during research you discover the scope was wrong (e.g. the data turns
out to come from a service you hadn't considered), update the scope
explicitly and tell the user before continuing.

### 3. Plan

Identify affected files and outline the approach. For non-trivial changes,
present the plan to the user before implementing. Consider side effects on
other parts of the system.

### 4. Branch

**Standalone mode:** Use the `/prepare-issue-branch` skill to create the
branch and prepare the commit message. It handles naming conventions, public
vs. private issue detection, and commit message formatting automatically.

**Attach mode:** Do _not_ invoke `/prepare-issue-branch`. The story branch
is already checked out (confirmed in step 1). Instead:

- Run `git fetch origin && git pull --rebase` to align with what colleagues
  have pushed since you started.
- If `git pull --rebase` produces conflicts, stop and ask the user to
  resolve them before continuing.
- Do not prepare a commit message yet — it will be written in step 8
  based on what was actually changed.

### 5. Implement

Write the code following the patterns described in the relevant agent reference
docs (graphql_patterns, frontend_patterns, service_patterns, etc.). Read the
relevant doc before starting implementation — do not read them all upfront.

### 6. Test

Run the specific tests affected by your changes. Write new tests for new
behavior. Never run the full test suite — CI handles comprehensive testing.

### 7. Review

Before committing, delegate the review to the `code-reviewer` sub-agent.
The sub-agent has its own context window and reviews the uncommitted diff
without bias from the implementation history.

The sub-agent will report findings grouped by severity (P0/P1/P2). If
findings are reported, return to step 5 (Implement) to address them, then
test again before re-running the review.

If the sub-agent reports no findings, proceed to commit.

### 8. Commit

Pre-commit hooks run linting and validation automatically. If you changed
the GraphQL schema or settings, the regenerate hook runs the appropriate
generators automatically.

**Standalone mode:** Use the prepared commit message from step 4
(`/prepare-issue-branch` wrote it to `.git/COMMIT_EDITMSG`).

**Attach mode:** Write a commit message that describes what this commit
changed — no issue reference, no `Closes`/`Fixes` keywords. The parent
story's MR carries the issue context; individual commits within it only
need to describe their own change. Keep it short and conventional, e.g.
`Add validation for empty subject on ticket form.`

### 9. Merge Request

**Standalone mode:** Use the `/create-mr` skill to push the branch and
create a Merge Request on GitLab. It selects the correct MR template, fills
in the sections, and targets the appropriate branch automatically.

**Attach mode:** Do _not_ invoke `/create-mr` — the MR for the parent story
already exists. Instead:

- Push the new commit to the existing remote branch: `git push origin
<current-branch>`.
- The push lands the commit on the existing MR automatically; CI re-runs.

CI runs automatically on MR creation (standalone) or push (attach). A human
review is required before merging.

### 10. Cherry-pick

If the fix also applies to `stable`, use the `/cherry-pick-to-stable` skill
after the MR is merged to `develop`.

## Rules

- Never push directly to `develop` or `stable`.
- Never reference private issue numbers in public commits.
- Never run the full test suite — always target specific files.
