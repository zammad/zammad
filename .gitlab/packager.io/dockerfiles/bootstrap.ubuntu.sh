#!/usr/bin/bash

set -eu

export DEBIAN_FRONTEND=noninteractive

cd "$(dirname $0)"

bash ./shared.deb.sh

echo "deb [signed-by=/usr/share/keyrings/zammad-archive-keyring.gpg] https://dl.packager.io/srv/deb/zammad/zammad/${CI_COMMIT_REF_NAME}/ubuntu ${DISTRIBUTION_VERSION} main" > /etc/apt/sources.list.d/zammad.list
apt-get update && apt-get install -y --download-only zammad