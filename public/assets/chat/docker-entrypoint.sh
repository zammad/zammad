#!/bin/bash

cd "${GULP_DIR}" || exit

yarn

gulp js css no-jquery
