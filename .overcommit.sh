#!/bin/bash

set -eux

# Don't require redis.
export ZAMMAD_SAFE_MODE=1

echo "Checking .pot catalog consistency..."
rails generate zammad:translation_catalog --check

.gitlab/check_graphql_api_consistency.sh