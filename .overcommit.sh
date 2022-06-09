#!/bin/bash

set -eux

echo "Checking .pot catalog consistency..."
rails generate translation_catalog --check

.gitlab/check_graphql_api_consistency.sh