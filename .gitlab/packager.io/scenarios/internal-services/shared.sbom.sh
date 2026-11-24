#!/usr/bin/bash

set -eu

# A broken scan configuration still produces a valid, but incomplete SBOM.
# Same check as .gitlab/sbom/verify.sh, which is outside of the image's build context.
SBOM=/opt/zammad/sbom.cdx.json

if [ ! -s "$SBOM" ]; then
  echo "The SBOM ${SBOM} is missing or empty." >&2
  exit 1
fi

for PURL in pkg:gem/rails pkg:npm/vue pkg:generic/ruby; do
  if ! grep -qF "\"${PURL}@" "$SBOM"; then
    echo "The SBOM ${SBOM} lacks ${PURL}." >&2
    exit 1
  fi
done

for PURL in pkg:gem/rspec-rails pkg:npm/vitest; do
  if grep -qF "\"${PURL}@" "$SBOM"; then
    echo "The SBOM ${SBOM} lists the development dependency ${PURL}, which must not ship." >&2
    exit 1
  fi
done

echo "The SBOM ${SBOM} was validated successfully."
