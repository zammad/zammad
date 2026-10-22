#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Hook: block `git commit` and `git push` of a coding agent while the branch
#   fails the fallow audit. Claude Code and Codex pass the tool call as JSON on
#   stdin and treat exit 2 as a block; every other command passes through.
#   The findings of a `warn` verdict reach the agent as additional context and
#   let the command run.

HOOKS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Global git options may sit between `git` and the subcommand (`git -c k=v commit`).
node -e '
  let input = ""
  process.stdin.on("data", (chunk) => (input += chunk)).on("end", () => {
    let command = ""
    try { command = JSON.parse(input).tool_input?.command ?? "" } catch {}
    const gitWrite = /(^|[\s;&|(])git(\s+-\S+(\s+[^-\s]\S*)?)*\s+(commit|push)(\s|$)/
    process.exit(gitWrite.test(command) ? 0 : 1)
  })
' || exit 0

ADVICE=$("$HOOKS_DIR/fallow-audit.sh" --gate-marker agent) || exit $?
[[ -z $ADVICE ]] && exit 0

ADVICE="$ADVICE" node -e '
  console.log(JSON.stringify({
    hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: process.env.ADVICE },
  }))
'
