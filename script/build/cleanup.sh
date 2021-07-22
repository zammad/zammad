#!/bin/bash

set -ex

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/
rm app/assets/javascripts/app/controllers/karma.coffee

# tests
rm -rf test
rm -rf spec
rm .rspec

# CI
rm -rf .github
rm .gitlab-ci.yml

# linting
rm -rf .rubocop
rm .csslintrc
rm .eslintignore
rm .eslintrc
rm .rubocop.yml
rm coffeelint.json
rm .overcommit.yml

# misc
rm .codeclimate.yml
rm .github_changelog_generator
