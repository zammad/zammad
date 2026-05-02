---
description: Start the full development workflow for a GitHub issue
---

# Work on issue

Work on the GitHub issue: $ARGUMENTS

Follow the development lifecycle defined in
`.dev/agent_docs/development_workflow.md`. Do not skip phases:

1. **Understand** — Read the issue thoroughly. Summarize the scope,
   acceptance criteria, and edge cases. Ask the user for clarification
   if anything is ambiguous.
2. **Research** — Identify the affected areas of the codebase. Read
   the agent reference docs from `.dev/agent_docs/` that apply to
   those areas.
3. **Plan** — Present a plan to the user: what files will change, the
   approach, potential side effects. Wait for approval before proceeding.

Stop after the Plan phase and wait for user approval before moving to
Branch / Implement / Test / Commit / Review / MR.
