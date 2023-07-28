#!/bin/bash

set -eu

# Don't require redis.
export ZAMMAD_SAFE_MODE=1

echo "Checking .pot catalog consistency..."
rails generate zammad:translation_catalog --check &

echo "Checking consistency of Settings types file..."
rails generate zammad:setting_types --check &

.gitlab/check_graphql_api_consistency.sh &

FAILED=0
for job in $(jobs -p)
do
  wait "$job" || (( FAILED+=1 ))
done

exit $FAILED