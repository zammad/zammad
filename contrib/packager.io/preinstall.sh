#!/bin/bash
#
# packager.io preinstall script
#

#
# Make sure that after installation/update there can be only one sprockets manifest,
#   the one coming from the package. The package manager will ignore any duplicate files
#   which might come from a backup restore and/or a manual 'assets:precompile' command run.
#   These duplicates can cause the application to fail, however.
#
rm -f /opt/zammad/public/assets/.sprockets-manifest-*.json || true