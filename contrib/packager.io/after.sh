#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$PATH

set -eux

# cleanup
script/build/cleanup.sh
