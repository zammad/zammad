#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Hook helper: audit the frontend changes of the branch with fallow.
# Exits 2 with the introduced findings on stderr when the verdict is `fail`.
#   A `warn` verdict exits 0 and prints its introduced findings on stdout as
#   advice, which the calling hook passes on to the agent without blocking.
#   A runtime error (missing base ref, fallow not installed) only logs a line:
#   the hook must never block for a reason unrelated to the code.

HOOKS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd "$(git rev-parse --show-toplevel)" || exit 2

# Merge requests target develop (or a stable branch), so that is the base.
#   fallow's own fallback is the branch's upstream, which on a pushed branch
#   is the branch itself.
BASE="${FALLOW_AUDIT_BASE:-origin/develop}"
if ! git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null; then
  echo "fallow audit skipped: base ref '$BASE' not found, set FALLOW_AUDIT_BASE." >&2
  exit 0
fi

REPORT=$(mktemp)
trap 'rm -f "$REPORT"' EXIT

pnpm exec fallow audit --base "$BASE" --format json --quiet "$@" >"$REPORT" 2>/dev/null
STATUS=$?

case $STATUS in
  0)
    if FINDINGS=$(node "$HOOKS_DIR/fallow-findings.mjs" "$REPORT" 2>/dev/null); then
      echo "fallow audit: the branch introduces warnings compared to $BASE; they do not block:"
      echo "$FINDINGS"
      echo "Address them while the code is open where the change allows it, see"
      echo "  .dev/agent_docs/code_analysis.md."
    fi
    exit 0
    ;;
  1)
    # pnpm also exits 1 when it cannot start fallow (not installed yet), so only a
    #   report with the `fail` verdict blocks.
    if FINDINGS=$(node "$HOOKS_DIR/fallow-findings.mjs" "$REPORT" 2>/dev/null); then
      {
        echo "fallow audit: the branch introduces findings compared to $BASE that block it:"
        echo "$FINDINGS"
        echo "Fix them. A finding that is wrong for a reason fallow cannot see is configured or"
        echo "  suppressed with the reason, see .dev/agent_docs/code_analysis.md. Work that is"
        echo "  not wired up yet shows as unused: finish it rather than deleting it."
      } >&2
      exit 2
    elif [[ -n $FINDINGS ]]; then
      # A `fail` verdict that attributes nothing to the branch (inherited findings
      #   only, or a category the helper does not list) is reported, not blocked.
      echo "fallow audit: $FINDINGS" >&2
      exit 0
    fi
    ;;
esac

echo "fallow audit skipped: fallow exited with status $STATUS: $(grep -v '^[[:space:]]*$' "$REPORT" | tr '\n' ' ' | head -c 300)" >&2
exit 0
