#!/bin/bash

set -ex

GITHUB_DEST=$1

git remote prune origin

if echo $CI_BUILD_REF_NAME | grep -E "^(private|cherry-pick-|renovate/|dependabot/)"; then
  echo 'Do not sync internal branches.'
  exit 0
fi

git checkout $CI_BUILD_REF_NAME
if [ "$CI_BUILD_REF_NAME" != "$CI_BUILD_TAG" ]; then
  git reset --hard origin/$CI_BUILD_REF_NAME
fi

if git remote | grep github > /dev/null; then
  git remote rm github
fi
git remote add github $GITHUB_DEST

if [ "$CI_BUILD_REF_NAME" != "$CI_BUILD_TAG" ]; then
  git push -f github $CI_BUILD_REF_NAME
else
  git push github --tags
fi
