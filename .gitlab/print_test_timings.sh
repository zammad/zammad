#!/bin/bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Print the test runtimes recorded by this job, so that
#   script/build/update_test_timings.rb can pick them up from the job log.

set -e

TIMINGS_FILE="${CI_TEST_TIMINGS_PATH:-tmp/test_timings/timings.yml}"

if [ ! -f "$TIMINGS_FILE" ]; then
  exit 0
fi

echo -e "\\e[0Ksection_start:$(date +%s):test_timings[collapsed=true]\\r\\e[0Krecorded test runtimes"
grep -E '^(spec|test)/.*\.rb: [0-9.]+$' "$TIMINGS_FILE" || true
echo -e "\\e[0Ksection_end:$(date +%s):test_timings\\r\\e[0K"
