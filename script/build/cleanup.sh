#!/bin/bash

set -eux

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/

# tests
rm -rf test spec app/frontend/tests .cypress
find app/frontend/ -type d -name __tests__ -exec rm -rf {} +
rm .rspec

# Histoire
find app/frontend/ -name '*.story.vue' -exec rm {} +

# Remove our customized .yarnrc to let yarn use the global cache
#   instead of .yarn/cache which would go into the packages.
rm .yarnrc

# CI
rm -rf .github .gitlab
rm .gitlab-ci.yml

# linting
# Since the .eslint-plugin-zammad folder is a dependency in package.json (required by assets:precompile), it cannot be removed.
rm .rubocop.yml
rm -rf .rubocop
rm .stylelintrc.json .eslintignore .eslintrc .eslintrc.js .prettierrc.json
rm coffeelint.json
rm -rf .coffeelint
rm .overcommit.*

# misc
rm .codeclimate.yml

# developer manual
rm -rf doc/developer_manual
