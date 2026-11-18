#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$(pwd)/.heroku/node/bin:$PATH

SYFT_VERSION=1.56.0
SYFT_SHA256=1c2493cfcf52d3367d6cb25780d9190c111c2219c34c820574c43e8bae15c528

set -eux

# The JS dependencies only exist compiled into the assets. Their SBOM is generated while
#   node_modules still exists, which provides the licenses.
pnpm sbom --prod --sbom-format cyclonedx --sbom-type application > pnpm-lock.cdx.json

# cleanup
script/build/cleanup.sh

# Ship the SBOM of the package contents as sbom.cdx.json, scanned after the cleanup so it
#   lists only what ends up in the package.
SYFT_DIR=$(mktemp -d)
curl -fsSL -o "${SYFT_DIR}/syft.tar.gz" "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz"
echo "${SYFT_SHA256}  ${SYFT_DIR}/syft.tar.gz" | sha256sum --check --strict
tar -xzf "${SYFT_DIR}/syft.tar.gz" -C "${SYFT_DIR}" syft

"${SYFT_DIR}/syft" scan dir:. \
  --profile installation \
  --source-name zammad \
  --source-version "$(cat VERSION)" \
  --output cyclonedx-json=sbom.cdx.json

rm -rf "${SYFT_DIR}" pnpm-lock.cdx.json
