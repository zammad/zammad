#!/bin/bash

set -e

TEMPDIR=$(mktemp -d)
trap 'rm -rf $TEMPDIR' EXIT

# Publish only for commits in 'stable' and for release tags (e.g. 5.4.1).
if [ "$CI_COMMIT_TAG" ]
then
  if [[ "$CI_COMMIT_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
  then
    echo "Tag $CI_COMMIT_TAG found, proceeding with the build."
  else
    echo "Commit for an unsupported tag name found, aborting."
    exit 0  # Can happen, don't throw an error.
  fi
else
  if [ "$CI_COMMIT_BRANCH" == 'stable' ]
  then
    echo "Commit for the stable branch found, proceeding with the build."
  else
    echo "Push for a branch other than stable found, aborting."
    exit 1  # Should not happen with correct CI config, raise an error.
  fi
fi

script/build/cleanup.sh

( find . -type d -name ".git" \
  && find . -name ".gitignore" \
  && find . -name ".gitkeep" \
  && find . -name ".gitmodules" ) | xargs rm -rf

echo "Building archives..."
tar -czf "${TEMPDIR}/zammad-latest.tar.gz" . > /dev/null
tar -cjf "${TEMPDIR}/zammad-latest.tar.bz2" . > /dev/null
zip -r "${TEMPDIR}/zammad-latest.zip" ./* > /dev/null

if [ "$CI_COMMIT_TAG" ]
then
  cp "${TEMPDIR}/zammad-latest.tar.gz" "${TEMPDIR}/zammad-${CI_COMMIT_TAG}.tar.gz"
  cp "${TEMPDIR}/zammad-latest.tar.bz2" "${TEMPDIR}/zammad-${CI_COMMIT_TAG}.tar.bz2"
  cp "${TEMPDIR}/zammad-latest.zip" "${TEMPDIR}/zammad-${CI_COMMIT_TAG}.zip"
fi

echo '#'
echo "# MD5 sums for the release notes"
echo "#"
(cd "$TEMPDIR"; md5sum -- *; echo '#'; ls -lah -- *; echo '#')

#
# Upload to FTP Server
#
if [ -z "$FTP_ZAMMAD_COM_SCP_TARGET" ]
then
  echo "Error: the required environment variable FTP_ZAMMAD_COM_SCP_TARGET is missing."
  exit 1
fi
echo "Upload files to ${FTP_ZAMMAD_COM_SCP_TARGET}…"
scp "$TEMPDIR"/* "$FTP_ZAMMAD_COM_SCP_TARGET"
