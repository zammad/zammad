#!/bin/bash

set -eu

# Don't require redis.
export ZAMMAD_SAFE_MODE=1

echo "Checking .pot catalog consistency..."
rails generate zammad:translation_catalog --check &

.gitlab/check_graphql_api_consistency.sh &

FAILED=0
for job in $(jobs -p)
do
  wait $job || let "FAILED+=1"
done

exit $FAILED