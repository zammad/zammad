#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$PATH

set -e

# delete asset cache
rm -r tmp/cache
