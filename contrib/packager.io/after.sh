#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$PATH

set -eux

# delete asset cache
rm -r tmp/cache

# delete node_modules folder - only required for building
rm -rf node_modules
