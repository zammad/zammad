#!/bin/bash

set -eux

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/
rm app/assets/javascripts/app/controllers/karma.coffee

# tests
rm -rf test
rm -rf spec
rm .rspec
rm -rf app/frontend/tests

# CI
rm -rf .github
rm .gitlab-ci.yml

# linting
rm -rf .rubocop
rm .stylelintrc.json
rm .eslintignore
rm .eslintrc
rm .eslintrc.js
rm -r .eslint/
rm .rubocop.yml
rm coffeelint.json
rm .overcommit.yml
rm .prettierrc.json

# misc
rm .codeclimate.yml
