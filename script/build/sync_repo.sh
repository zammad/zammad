#!/bin/bash

set -ex

GITHUB_DEST=$1

# This can be called for branches or tags. Filter out private branches first.
if [[ $CI_COMMIT_REF_NAME =~ ^(private|cherry-pick-|revert-|renovate|dependabot) ]]
then
  echo "Do not sync internal branch ${CI_COMMIT_REF_NAME}."
  exit 0
fi

# Keep things tidy.
git remote prune origin

# Make sure github remote is up-to-date.
if git remote | grep github > /dev/null
then
  git remote rm github
fi
git remote add github "$GITHUB_DEST"

if [ "$CI_COMMIT_TAG" ]
then
  # Tag
  git push github --tags -f
else
  # Commit
  git checkout "$CI_COMMIT_REF_NAME"
  git reset --hard origin/"$CI_COMMIT_REF_NAME"
  git push -f github "$CI_COMMIT_REF_NAME"
fi
