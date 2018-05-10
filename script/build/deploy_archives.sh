#!/bin/bash

set -ex

if [ "$CI_BUILD_REF_NAME" != "$CI_BUILD_TAG" ]; then
  echo 'deploy archives only for tag releases'
  exit 0
fi

# cleanup
cleanup.sh

( find . -type d -name ".git" \
  && find . -name ".gitignore" \
  && find . -name ".gitkeep" \
  && find . -name ".gitmodules" ) | xargs rm -rf

# tar.gz
tar -czf /tmp/zammad-${CI_BUILD_TAG}.tar.gz .

# tar.bz2
tar -cjf /tmp/zammad-${CI_BUILD_TAG}.tar.bz2 .

# zip
zip -r /tmp/zammad-${CI_BUILD_TAG}.zip ./*

# publish
scp /tmp/zammad-${CI_BUILD_TAG}.tar.* $ARCHIVE_SCP_TARGET
scp /tmp/zammad-${CI_BUILD_TAG}.zip $ARCHIVE_SCP_TARGET
