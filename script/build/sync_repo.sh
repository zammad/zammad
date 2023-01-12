#!/bin/bash

set -ex

GITHUB_DEST=$1

# This can be called for branches or tags. Filter out private branches first.
if [[ $CI_COMMIT_BRANCH =~ ^(private|cherry-pick-|renovate/|dependabot/) ]]
then
  echo "Do not sync internal branch ${CI_COMMIT_BRANCH}."
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

if [ "$CI_COMMIT_BRANCH" ]
then
  # Commit
  git checkout "$CI_COMMIT_BRANCH"
  git reset --hard origin/"$CI_COMMIT_BRANCH"
  git push -f github "$CI_COMMIT_BRANCH"
else
  # Tag
  git push github --tags
fi
