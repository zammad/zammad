#!/usr/bin/env bash
#
# build zammads docker & docker-compose images

set -o errexit
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_USER="zammad"
ZAMMAD_VERSION="$(git describe --tags | sed -e 's/-[a-z0-9]\{8,\}.*//g')"
export ZAMMAD_VERSION

if [ "${CIRCLE_BRANCH}" == 'develop' ]; then
  DOCKER_REPOSITORY="zammad-docker"
  BUILD_SCRIPT="scripts/build_image.sh"
elif [ "${CIRCLE_BRANCH}" == 'stable' ]; then
  DOCKER_REPOSITORY="zammad-docker-compose"
  BUILD_SCRIPT="hooks/build.sh"
else
  echo "branch is ${CIRCLE_BRANCH}... no docker image build needed..."
  exit 0
fi

# dockerhub auth
echo "${DOCKER_PASSWORD}" | docker login --username="${DOCKER_USERNAME}" --password-stdin

# clone docker repo
git clone https://github.com/"${REPO_USER}"/"${DOCKER_REPOSITORY}"

# enter dockerfile dir
cd "${REPO_ROOT}/${DOCKER_REPOSITORY}"

# build & push docker image
# shellcheck disable=SC1090
source "${REPO_ROOT}/${DOCKER_REPOSITORY}/${BUILD_SCRIPT}"
