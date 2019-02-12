#!/bin/sh
#
# lint bash scripts
#

set -o errexit

CONFIG_DIR="./.circleci"
TMP_FILE="$(mktemp)"

find "${CONFIG_DIR}" -type f -name "*.sh" > "${TMP_FILE}"

while read -r FILE; do
  echo lint "${FILE}"
  shellcheck -x "${FILE}"
done < "${TMP_FILE}"

rm "${TMP_FILE}"
