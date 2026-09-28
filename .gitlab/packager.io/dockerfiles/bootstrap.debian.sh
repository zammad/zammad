#!/usr/bin/bash

set -eu

export DEBIAN_FRONTEND=noninteractive

cd "$(dirname $0)"

# Debian 11 LTS has ended and its security updates were removed from deb.debian.org, but not yet added to archive.debian.org.
if [ "${DISTRIBUTION_VERSION}" = "11" ]; then
  sed -i 's#^deb http://deb.debian.org/debian-security bullseye-security main$#deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260830T000000Z bullseye-security main#' /etc/apt/sources.list
fi

bash ./shared.deb.sh

echo "deb [signed-by=/usr/share/keyrings/zammad-archive-keyring.gpg] https://go.packager.io/srv/deb/zammad/zammad/${CI_COMMIT_REF_NAME}/debian ${DISTRIBUTION_VERSION} main" > /etc/apt/sources.list.d/zammad.list
apt-get update && apt-get install -y --download-only zammad