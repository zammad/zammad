#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Hook: regenerate generated files, then lint.

# Agents start all hooks of one event concurrently, so a separate lint hook would
#   type-check while the regeneration is still writing the generated types.
HOOKS_DIR=$(dirname "${BASH_SOURCE[0]}")
EXIT_CODE=0

"$HOOKS_DIR/regenerate-after-edit.sh" || EXIT_CODE=2
"$HOOKS_DIR/lint-after-edit.sh" || EXIT_CODE=2

exit $EXIT_CODE
