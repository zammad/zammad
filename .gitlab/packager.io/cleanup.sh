#!/bin/sh

set -eu

cd "$(dirname $0)"

docker compose down --timeout 0
docker volume prune --all --force

DELETE_IMAGES=$(docker image ls "zammad-packagerio-ci-${CI_JOB_ID}" -q)
if [ -n "$DELETE_IMAGES" ]
then
  # shellcheck disable=SC2086
  docker image rm $DELETE_IMAGES
fi