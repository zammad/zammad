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

# remove local files of the packages
if [ -n "$(which zammad 2> /dev/null)" ]; then
   PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

   RAKE_TASKS=$(zammad run rake --tasks | grep "zammad:package:uninstall_all_files")

   if [[ x$RAKE_TASKS == 'x' ]]; then
      echo "# Code does not yet fit, skipping automatic package uninstall."
      echo "... This is not an error and will work during your next upgrade ..."
      exit 0
   fi

   if [ "$(zammad run rails r 'puts Package.count.positive?')" == "true" ] && [ -n "$(which yarn 2> /dev/null)" ] && [ -n "$(which node 2> /dev/null)" ]; then
      echo "# Detected custom packages..."
      echo "# Remove custom packages files temporarily..."
      zammad run rake zammad:package:uninstall_all_files
   fi
fi
