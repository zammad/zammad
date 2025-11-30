#!/usr/bin/env bash
# Generate comprehensive CI summary report

set -o pipefail

echo "Generating CI Summary Report..."

SUMMARY_FILE="ci-summary.md"

cat > "$SUMMARY_FILE" << 'EOF'
# CI Pipeline Execution Summary

## Pipeline Overview

This document provides a detailed summary of the CI pipeline execution.

EOF

# Add timestamp
echo "**Generated**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Parse status file
if [ -f ci-status.env ]; then
  echo "## Execution Results" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"

  # Count successes and failures
  SUCCESS_COUNT=$(grep -c "=success\|=hit" ci-status.env || echo "0")
  FAIL_COUNT=$(grep -c "=failed" ci-status.env || echo "0")
  MISS_COUNT=$(grep -c "=miss" ci-status.env || echo "0")

  echo "- ✅ Successful Steps: $SUCCESS_COUNT" >> "$SUMMARY_FILE"
  echo "- ❌ Failed Steps: $FAIL_COUNT" >> "$SUMMARY_FILE"
  echo "- ⚠️  Cache Misses: $MISS_COUNT" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"

  echo "### Detailed Step Results" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"

  # Parse each line
  while IFS='=' read -r key value; do
    if [ -n "$key" ] && [ -n "$value" ]; then
      case "$value" in
        success)
          echo "- ✅ **$key**: SUCCESS" >> "$SUMMARY_FILE"
          ;;
        failed)
          echo "- ❌ **$key**: FAILED" >> "$SUMMARY_FILE"
          ;;
        hit)
          echo "- ✅ **$key**: Cache Hit" >> "$SUMMARY_FILE"
          ;;
        miss)
          echo "- ⚠️  **$key**: Cache Miss" >> "$SUMMARY_FILE"
          ;;
        *)
          echo "- ❓ **$key**: $value" >> "$SUMMARY_FILE"
          ;;
      esac
    fi
  done < ci-status.env

  echo "" >> "$SUMMARY_FILE"
fi

# Add log file information
echo "## Available Artifacts" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "The following log files have been generated:" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

for log_file in *.log; do
  if [ -f "$log_file" ]; then
    SIZE=$(du -h "$log_file" | cut -f1)
    LINES=$(wc -l < "$log_file")
    echo "- **$log_file** ($SIZE, $LINES lines)" >> "$SUMMARY_FILE"
  fi
done

echo "" >> "$SUMMARY_FILE"

# Add recommendations
echo "## Recommendations" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "### ⚠️  Action Required" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"
  echo "The CI pipeline encountered failures. Please:" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"
  echo "1. Review the error logs above" >> "$SUMMARY_FILE"
  echo "2. Fix the identified issues" >> "$SUMMARY_FILE"
  echo "3. Push the corrections to trigger a new CI run" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"
else
  echo "### ✅ All Clear" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"
  echo "All CI checks passed successfully. This PR is ready for review!" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"
fi

# Add debugging tips
if grep -q "=failed" ci-status.env 2>/dev/null; then
  echo "## Debugging Failed Steps" >> "$SUMMARY_FILE"
  echo "" >> "$SUMMARY_FILE"

  if grep -q "pre_setup=failed" ci-status.env; then
    echo "### Pre-Setup Failure" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Common causes:" >> "$SUMMARY_FILE"
    echo "- Gemfile.lock out of sync (run \`bundle install\` locally)" >> "$SUMMARY_FILE"
    echo "- pnpm-lock.yaml issues (run \`pnpm install\` locally)" >> "$SUMMARY_FILE"
    echo "- Database migration errors (check migration syntax)" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
  fi

  if grep -q "lint=failed" ci-status.env; then
    echo "### Linting Failure" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Common causes:" >> "$SUMMARY_FILE"
    echo "- Rubocop violations (run \`bundle exec rubocop\` locally)" >> "$SUMMARY_FILE"
    echo "- ESLint violations (run \`pnpm lint:js\` locally)" >> "$SUMMARY_FILE"
    echo "- Stylelint violations (run \`pnpm lint:css\` locally)" >> "$SUMMARY_FILE"
    echo "- Brakeman security issues (run \`bundle exec brakeman\` locally)" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
  fi

  if grep -q "test=failed" ci-status.env; then
    echo "### Test Failure" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Common causes:" >> "$SUMMARY_FILE"
    echo "- RSpec failures (run \`bundle exec rspec\` locally)" >> "$SUMMARY_FILE"
    echo "- Minitest failures (run \`bundle exec rake test:units\` locally)" >> "$SUMMARY_FILE"
    echo "- Frontend test failures (run \`pnpm test\` locally)" >> "$SUMMARY_FILE"
    echo "- Database schema issues (run \`rails db:migrate RAILS_ENV=test\`)" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
  fi

  if grep -q "markdownlint=failed" ci-status.env; then
    echo "### Markdown Linting Failure" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Common causes:" >> "$SUMMARY_FILE"
    echo "- Missing blank lines around headings" >> "$SUMMARY_FILE"
    echo "- Incorrect list indentation" >> "$SUMMARY_FILE"
    echo "- Trailing spaces" >> "$SUMMARY_FILE"
    echo "- Run \`pnpm lint:md\` locally to fix" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
  fi
fi

# Add timing information if available
echo "## Execution Timeline" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Check the GitHub Actions UI for detailed timing information." >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Footer
echo "---" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "*This summary was automatically generated by the CI pipeline.*" >> "$SUMMARY_FILE"

echo "✅ Summary report generated: $SUMMARY_FILE"

# Also output to GitHub Step Summary if available
if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  cat "$SUMMARY_FILE" >> "$GITHUB_STEP_SUMMARY"
fi
