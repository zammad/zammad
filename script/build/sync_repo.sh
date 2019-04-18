#!/bin/bash

set -ex

GITHUB_DEST=$1

if echo $CI_BUILD_REF_NAME | grep private; then
  echo 'sync no private branches'
  exit 0
fi

if echo $CI_BUILD_REF_NAME | grep cherry-pick-; then
  echo 'sync no cherry-pick branches'
  exit 0
fi

if echo $CI_BUILD_REF_NAME | grep dependabot/; then
  echo 'sync no dependabot branches'
  exit 0
fi

git checkout $CI_BUILD_REF_NAME
if [ "$CI_BUILD_REF_NAME" != "$CI_BUILD_TAG" ]; then
  git pull --rebase origin $CI_BUILD_REF_NAME
fi

if git remote | grep github > /dev/null; then
  git remote rm github
fi
git remote add github $GITHUB_DEST

if [ "$CI_BUILD_REF_NAME" != "$CI_BUILD_TAG" ]; then
  git push github $CI_BUILD_REF_NAME
else
  git push github --tags
fi
