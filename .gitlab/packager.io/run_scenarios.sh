#!/bin/sh

set -eu

: "${DISTRO:=debian-12}"
DISTRIBUTION="${DISTRO%%-*}"
DISTRIBUTION_VERSION="${DISTRO#*-}"
: "${CI_JOB_ID:=1}"
: "${CI_COMMIT_REF_NAME:=develop}"

export DISTRIBUTION DISTRIBUTION_VERSION CI_JOB_ID CI_COMMIT_REF_NAME

echo "Running tests for ${CI_COMMIT_REF_NAME} on ${DISTRIBUTION}-${DISTRIBUTION_VERSION}…"

cd "$(dirname "$0")"

docker compose build

# shellcheck disable=SC2043
for SCENARIO in $(cd scenarios; ls -1)
do
  docker compose down --timeout 0 --volumes
  docker compose up -d
  docker compose exec zammad bash "/scenarios/${SCENARIO}/${DISTRIBUTION}.sh"
  docker compose down --timeout 0 --volumes || true # Ignore "prune operation is already running" errors.
done
./cleanup.sh
