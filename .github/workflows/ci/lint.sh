#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh
# shellcheck disable=SC1091
source .gitlab/environment.env

echo "Checking .po file syntax..."
for FILE in i18n/*.pot i18n/*.po; do echo "Checking $FILE"; msgfmt -o /dev/null -c "$FILE"; done
echo "Checking .pot catalog consistency..."
bundle exec rails generate zammad:translation_catalog --check
echo "Brakeman security check..."
bundle exec brakeman -o /dev/stdout -o tmp/brakeman-report.html
echo "Rails zeitwerk:check autoloader check..."
bundle exec rails zeitwerk:check
.gitlab/check_graphql_api_consistency.sh
echo "Rubocop check..."
bundle exec .rubocop/validate_todos.rb
bundle exec rubocop --parallel
echo "Coffeelint check..."
coffeelint --rules ./.coffeelint/rules/* app/
echo "Stylelint check..."
yarn lint:css
echo "ESLint check..."
yarn lint