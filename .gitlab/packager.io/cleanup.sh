#!/bin/sh

set -eu

cd "$(dirname $0)"

docker compose down --timeout 0 --volumes || true # Ignore "prune operation is already running" errors.

DELETE_IMAGES=$(docker image ls "zammad-packagerio-ci-${CI_JOB_ID}" -q)
if [ -n "$DELETE_IMAGES" ]
then
  # shellcheck disable=SC2086
  docker image rm $DELETE_IMAGES
fi