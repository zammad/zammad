#!/bin/bash
#
# packager.io before script
#

set -eux

# print environment
uname -a
ruby -v
env

# Use more detailed version information including packager.io build info.
if [ -z "${APP_PKG_ITERATION}" ]
then
  echo "Error: could not find version information, aborting."
  exit 1
fi

ZAMMAD_VERSION="$APP_PKG_VERSION-$APP_PKG_ITERATION"
echo "Setting VERSION information to $ZAMMAD_VERSION"
echo "$ZAMMAD_VERSION" > VERSION

# We can only install additional packages after epel-release is installed, so we need to do this here.
if [[ "${TARGET}" == el:* ]]
then
  if command -v dnf > /dev/null 2>&1; then
    dnf install -y imlib2-devel || exit 1
  else
    yum install -y imlib2-devel || exit 1
  fi
fi
