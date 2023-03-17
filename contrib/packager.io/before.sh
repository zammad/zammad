#!/bin/bash
#
# packager.io before script
#

set -eux

# print environemnt
uname -a
ruby -v
env
cat Gemfile.lock

# Use more detailed version information including packager.io build info.
if [ -z "${APP_PKG_ITERATION}" ]
then
  echo "Error: could not find version information, aborting."
  exit 1
fi

ZAMMAD_VERSION="$APP_PKG_VERSION-$APP_PKG_ITERATION"
echo "Setting VERSION information to $ZAMMAD_VERSION"
echo "$ZAMMAD_VERSION" > VERSION

# cleanup
script/build/cleanup.sh
