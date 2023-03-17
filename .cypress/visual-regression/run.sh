#!/usr/bin/env bash

yarn install --frozen-lockfile --ignore-scripts
yarn cypress:install --frozen-lockfile
yarn test:ci:ct --env pluginVisualRegressionUpdateImages=$CYPRESS_UPDATE_SNAPSHOTS --spec '../**/*-visuals.cy.*'
