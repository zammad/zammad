#!/usr/bin/bash

set -eu

export DEBIAN_FRONTEND=noninteractive

cd "$(dirname $0)"

# Debian 11 reached its LTS end of life on 2026-08-31. deb.debian.org still serves the
# bullseye and bullseye-security indexes, but the matching pool files were removed, so every
# install fails with a 404. The base image ships commented-out snapshot.debian.org sources
# pinned to the timestamp it was built from, which still carry those files, so switch the
# container over to them. Their Release files are expired by design, hence the
# Check-Valid-Until override.
if [ "${DISTRIBUTION_VERSION}" = "11" ]; then
  sed -i -e 's|^# deb http://snapshot\.debian\.org|deb http://snapshot.debian.org|' \
         -e '\|^deb http://deb\.debian\.org|d' /etc/apt/sources.list

  if ! grep -q '^deb http://snapshot\.debian\.org' /etc/apt/sources.list; then
    echo "No snapshot.debian.org sources found in the base image, cannot build for an archived distribution." >&2
    exit 1
  fi

  echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
fi

bash ./shared.deb.sh

echo "deb [signed-by=/usr/share/keyrings/zammad-archive-keyring.gpg] https://go.packager.io/srv/deb/zammad/zammad/${CI_COMMIT_REF_NAME}/debian ${DISTRIBUTION_VERSION} main" > /etc/apt/sources.list.d/zammad.list
apt-get update && apt-get install -y --download-only zammad
