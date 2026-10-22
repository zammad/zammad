#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Hook: regenerate generated files, then lint.
#   `--agent codex` selects the output format Codex accepts; Claude Code is the default.

# Agents start all hooks of one event concurrently, so a separate lint hook would
#   type-check while the regeneration is still writing the generated types.
HOOKS_DIR=$(dirname "${BASH_SOURCE[0]}")
AGENT=claude
[[ $1 == --agent ]] && AGENT=$2
EXIT_CODE=0

"$HOOKS_DIR/regenerate-after-edit.sh" || EXIT_CODE=2
# The linters write to stderr; stdout only carries the advice of a `warn` audit.
ADVICE=$("$HOOKS_DIR/lint-after-edit.sh") || EXIT_CODE=2

# Advice continues the turn in Claude Code, so the same advice is given only once.
ADVICE_FILE=$(git rev-parse --path-format=absolute --git-path fallow-advice)
if [[ -z $ADVICE ]]; then
  rm -f "$ADVICE_FILE"
  exit $EXIT_CODE
fi
[[ $ADVICE == "$(cat "$ADVICE_FILE" 2>/dev/null)" ]] && exit $EXIT_CODE
printf '%s\n' "$ADVICE" >"$ADVICE_FILE"

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "$ADVICE" >&2
  exit $EXIT_CODE
fi

# A Codex Stop hook cannot add context for the model, so Codex shows the advice
#   to the user instead.
ADVICE="$ADVICE" node -e '
  const advice = process.env.ADVICE
  console.log(JSON.stringify(process.argv[1] === "codex"
    ? { systemMessage: advice }
    : { hookSpecificOutput: { hookEventName: "Stop", additionalContext: advice } }))
' "$AGENT"
