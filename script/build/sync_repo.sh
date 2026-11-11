#!/bin/bash

set -ex

GITHUB_DEST=$1

# This can be called for branches or tags. Filter out private branches first.
if [[ $CI_COMMIT_REF_NAME =~ ^(private|cherry-pick-|revert-|renovate|dependabot) ]]
then
  echo "Do not sync internal branch ${CI_COMMIT_REF_NAME}."
  exit 0
fi

# Make sure github remote is up-to-date.
if git remote | grep github > /dev/null
then
  git remote rm github
fi
git remote add github "$GITHUB_DEST"

if [ "$CI_COMMIT_TAG" ]
then
  LOCAL_REF="refs/tags/${CI_COMMIT_TAG}"
  REMOTE_REF="refs/tags/${CI_COMMIT_TAG}"
else
  LOCAL_REF="refs/remotes/origin/${CI_COMMIT_REF_NAME}"
  REMOTE_REF="refs/heads/${CI_COMMIT_REF_NAME}"
fi
FETCH_REFSPEC="+${REMOTE_REF}:${LOCAL_REF}"

# GitHub only accepts a push from a shallow clone if it already has the oldest fetched commits,
#   so fetch enough recent history to reach them instead of the whole repository.
git fetch --no-tags --depth=50 origin "$FETCH_REFSPEC"

if ! git push -f github "${LOCAL_REF}:${REMOTE_REF}"
then
  echo "GitHub does not have the oldest fetched commits, retrying with the full history of ${CI_COMMIT_REF_NAME}."
  git fetch --no-tags --unshallow origin "$FETCH_REFSPEC"
  git push -f github "${LOCAL_REF}:${REMOTE_REF}"
fi
