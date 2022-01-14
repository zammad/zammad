#!/bin/bash

cd "${GULP_DIR}" || exit

yarn

gulp svgstore
