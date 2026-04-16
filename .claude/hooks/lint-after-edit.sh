#!/bin/bash
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Hook: lint all changed/new files with the appropriate tools.
# Collects modified and untracked files from git, then runs the matching linters.

RUBY_FILES=()
FRONTEND_JS_FILES=()
COFFEESCRIPT_FILES=()
STYLE_FILES=()
MARKDOWN_FILES=()
EXIT_CODE=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    *.rb)               RUBY_FILES+=("$file") ;;
    *.ts|*.vue|*.js)    FRONTEND_JS_FILES+=("$file") ;;
    *.coffee)           COFFEESCRIPT_FILES+=("$file") ;;
    *.scss|*.css)       STYLE_FILES+=("$file") ;;
    *.md)               MARKDOWN_FILES+=("$file") ;;
  esac
done < <(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

if [[ ${#RUBY_FILES[@]} -gt 0 ]]; then
  bundle exec rubocop --autocorrect "${RUBY_FILES[@]}" >&2 || EXIT_CODE=2
fi

if [[ ${#FRONTEND_JS_FILES[@]} -gt 0 ]]; then
  { pnpm lint:js:oxlint:cmd --fix "${FRONTEND_JS_FILES[@]}" && \
    pnpm lint:js:eslint:cmd --fix "${FRONTEND_JS_FILES[@]}" && \
    pnpm format:cmd "${FRONTEND_JS_FILES[@]}" && \
    pnpm lint:ts; } >&2 || EXIT_CODE=2
fi

if [[ ${#COFFEESCRIPT_FILES[@]} -gt 0 ]]; then
  coffeelint --reporter=csv --rules ./.dev/coffeelint/rules/detect_translatable_string.coffee "${COFFEESCRIPT_FILES[@]}" >&2 || EXIT_CODE=2
fi

if [[ ${#STYLE_FILES[@]} -gt 0 ]]; then
  pnpm lint:css:cmd --fix "${STYLE_FILES[@]}" >&2 || EXIT_CODE=2
fi

if [[ ${#MARKDOWN_FILES[@]} -gt 0 ]]; then
  pnpm lint:md:cmd --fix "${MARKDOWN_FILES[@]}" >&2 || EXIT_CODE=2
fi

exit $EXIT_CODE
