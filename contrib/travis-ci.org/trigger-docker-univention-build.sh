#!/bin/bash
#
# trigger build of https://github.com/zammad/zammad-docker-univention on https://travis-ci.org/zammad/zammad-docker-univention and upload it to https://hub.docker.com/r/zammad/zammad-docker-univention
#

REPO_USER="zammad"
REPO="zammad-docker-univention"
BRANCH="master"

if [ "${TRAVIS_BRANCH}" == 'stable' ]; then
  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Travis-API-Version: 3" \
    -H "Accept: application/json" \
    -H "Authorization: token ${TRAVIS_API_TOKEN}" \
    -d '{"request":{ "message": "'"${TRAVIS_COMMIT_MESSAGE}"'","branch":"'${BRANCH}'","config":{"env":{"ZAMMAD_VERSION":"'${ZAMMAD_VERSION}'"}}}}' \
    "https://api.travis-ci.org/repo/${REPO_USER}%2F${REPO}/requests"
fi
