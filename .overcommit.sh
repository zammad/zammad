#!/bin/bash

set -eux

echo "Checking .pot catalog consistency..."
rails generate zammad:translation_catalog --check

.gitlab/check_graphql_api_consistency.sh