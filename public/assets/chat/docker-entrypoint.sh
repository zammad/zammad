#!/bin/bash

cd "${GULP_DIR}" || exit

yarn

npx gulp js css no-jquery
