#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$PATH

set -e

# download locales and translations to make a offline installation possible
contrib/packager.io/fetch_locales.rb

# delete asset cache
rm -r tmp/cache

rm -r vendor/bundle/ruby/2.3.0 || true
