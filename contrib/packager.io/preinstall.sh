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

# Ensure database connectivity
if [[ -f /opt/zammad/config/database.yml ]]; then
   DB_HOST="$(grep -m 1 '^[[:space:]]*host:' < /opt/zammad/config/database.yml | sed -e 's/.*host:[[:space:]]*//g')"
   DB_PORT="$(grep -m 1 '^[[:space:]]*port:' < /opt/zammad/config/database.yml | sed -e 's/.*port:[[:space:]]*//g')"
   DB_USER="$(grep -m 1 '^[[:space:]]*username:' < /opt/zammad/config/database.yml | sed -e 's/.*username:[[:space:]]*//g')"
   DB_PASS="$(grep -m 1 '^[[:space:]]*password:' < /opt/zammad/config/database.yml | sed -e 's/.*password:[[:space:]]*//g')"
   DB_SOCKET="$(grep -m 1 '^[[:space:]]*socket:' < /opt/zammad/config/database.yml | sed -e 's/.*socket:[[:space:]]*//g')"
   DB_ADAPTER="$(grep -m 1 '^[[:space:]]*adapter:' < /opt/zammad/config/database.yml | sed -e 's/.*adapter:[[:space:]]*//g')"
else
   # Skip this whole script if we can't find our database file
   echo "Warning: Could not find database.yml"
   exit 0
fi

if [ "${DB_HOST}x" == "x" ]; then
   DB_HOST="localhost"
fi
if [ -n "$(which psql 2> /dev/null)" ] && [ "${DB_ADAPTER}" == 'postgresql' ]; then
   if [ "${DB_PORT}x" == "x" ]; then
      DB_PORT="5432"
   fi
   if [ "${DB_SOCKET}x" == "x" ]; then
      pg_isready -q -h $DB_HOST -p $DB_PORT
      state=$?
   else
      pg_isready -q
      state=$?
   fi
elif [ -n "$(which mysql 2> /dev/null)" ] && [ "${DB_ADAPTER}" == 'mysql2' ]; then
   if [ "${DB_PORT}x" == "x" ]; then
      DB_PORT="3306"
   fi
   mysqladmin status -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS > /dev/null
   state=$?
fi

# Check error state to ensure database is online
if [[ $state -gt 0 ]]; then
   echo "!!! ERROR !!!"
   echo "Your database does not seem to be online!"
   echo "Please check your configuration in config/database.yml and ensure the configured database server is online."
   echo "Exiting Zammad package installation / upgrade - try again."
   exit 1
fi

# remove local files of the packages
if [ -n "$(which zammad 2> /dev/null)" ]; then
   PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

   RAKE_TASKS=$(zammad run rake --tasks | grep "zammad:package:uninstall_all_files")

   if [[ x$RAKE_TASKS == 'x' ]]; then
      echo "# Code does not yet fit, skipping automatic package uninstall."
      echo "... This is not an error and will work during your next upgrade ..."
      exit 0
   fi

   if [ "$(zammad run rails r 'puts Package.count.positive?')" == "true" ] && [ -n "$(which pnpm 2> /dev/null)" ] && [ -n "$(which node 2> /dev/null)" ]; then
      echo "# Detected custom packages..."
      echo "# Remove custom packages files temporarily..."
      zammad run rake zammad:package:uninstall_all_files
   fi
fi
