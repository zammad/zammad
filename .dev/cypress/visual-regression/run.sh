#!/usr/bin/env bash

pnpm install --frozen-lockfile --ignore-scripts
pnpm cypress:install --frozen-lockfile
pnpm test:ci:ct --env pluginVisualRegressionUpdateImages=$CYPRESS_UPDATE_SNAPSHOTS --spec '../**/*-visuals.cy.*'
