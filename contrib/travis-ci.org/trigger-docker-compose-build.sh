#!/bin/bash
#
# trigger build of https://github.com/zammad/zammad-docker-compose on https://travis-ci.org/zammad/zammad-docker-compose and upload it to https://hub.docker.com/r/zammad/zammad-docker-compose/
#

if [ ${TRAVIS_BRANCH} == 'stable' ]; then
  curl -X POST -H "Content-Type: application/json" -H "Travis-API-Version: 3" -H "Accept: application/json" -H "Authorization: ${TRAVIS_API_TOKEN}" -d '{"request": {"branch": "master"}}' 'https://api.travis-ci.org/repo/monotek%2Fzammad-docker-compose/requests'
fi
