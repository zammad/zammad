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

# cleanup
script/build/cleanup.sh
