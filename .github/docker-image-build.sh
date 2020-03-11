#!/usr/bin/env bash
#
# build zammads docker & docker-compose images

set -o errexit
set -o pipefail

DOCKER_REGISTRY="index.docker.io"
REPO_ROOT="$(git rev-parse --show-toplevel)"
ZAMMAD_VERSION="$(git describe --tags | sed -e 's/-[a-z0-9]\{8,\}.*//g')"

# dockerhub auth
echo "${DOCKER_PASSWORD}" | docker login --username="${DOCKER_USERNAME}" --password-stdin

# clone docker repo
DOCKER_REPOSITORY_CLONE_URL="https://github.com/${REPO_USER}/${DOCKER_GITHUB_REPOSITORY}"
echo "Cloning ${DOCKER_REPOSITORY_CLONE_URL}"
git clone "${DOCKER_REPOSITORY_CLONE_URL}"

# enter dockerfile dir
cd "${REPO_ROOT}/${DOCKER_GITHUB_REPOSITORY}"

# shellcheck disable=SC2153
for DOCKER_IMAGE in ${DOCKER_IMAGES}; do
  echo "Build Zammad Docker image ${DOCKER_IMAGE} with version ${ZAMMAD_VERSION} for DockerHubs ${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY} repo"

  if [ "${DOCKER_REPOSITORY}" == "zammad-docker-compose" ]; then
    docker build --pull --no-cache --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" -t "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}" -t "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}-latest" -t "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}-${ZAMMAD_VERSION}" -f "containers/${DOCKER_IMAGE}/Dockerfile" .

    docker push "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}"
    docker push "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}-latest"
    docker push "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${DOCKER_IMAGE}-${ZAMMAD_VERSION}"
  else
    docker build --pull --no-cache --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" -t "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:latest" -t "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${ZAMMAD_VERSION}" .

    docker push "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:latest"
    docker push "${DOCKER_REGISTRY}/${REPO_USER}/${DOCKER_REPOSITORY}:${ZAMMAD_VERSION}"
  fi
done
