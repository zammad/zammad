#!/bin/bash

cd "${GULP_DIR}" || exit

gulp js css no-jquery
