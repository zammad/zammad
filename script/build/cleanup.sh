#!/bin/bash

set -eu

rm app/assets/javascripts/app/controllers/layout_ref.coffee
rm -rf app/assets/javascripts/app/views/layout_ref/

# tests
rm -rf test spec app/frontend/tests app/frontend/cypress
find app/frontend/ -type d -name __tests__ -exec rm -rf {} +
rm .rspec

# CI
rm -rf .github .gitlab
rm .gitlab-ci.yml
rm .coderabbit.yml

# linting
# Since the .eslint-plugin-zammad folder is a dependency in package.json (required by assets:precompile), it cannot be removed.
rm .rubocop.yml
rm .stylelintrc.json .oxlintrc.json eslint.config.ts .oxfmtrc.json
rm coffeelint.json
rm .markdownlint.yml
rm .overcommit.*
rm .gitleaks.toml

# Yard
rm .yardopts

# developer manual
rm -rf doc/developer_manual

# Various development files
rm -rf .dev .devcontainer

# AI
rm AGENTS.md
rm -rf .claude

# delete caches
rm -rf tmp/*
rm -rf log/*

# Delete node_modules folder - only required during building
rm -rf node_modules
