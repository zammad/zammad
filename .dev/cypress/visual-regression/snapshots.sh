#!/usr/bin/env bash

if [[ $(uname -m) == 'arm64' ]]; then
  # cannot run cypress while on arm, but in amd container
  docker compose -f .dev/cypress/visual-regression/docker-compose.arm.yml up --exit-code-from cypress
else
  docker compose -f .dev/cypress/visual-regression/docker-compose.amd64.yml up --exit-code-from cypress
fi
