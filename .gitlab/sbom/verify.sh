#!/bin/sh
#
# Usage: verify.sh SBOM PURL...
#
# Checks that a CycloneDX SBOM lists the given packages, by package URL without version,
#   e.g. pkg:gem/rails. A leading ! requires the package to be absent instead, e.g. for
#   development dependencies that must not ship.
# A broken scan configuration still produces a valid, but incomplete SBOM.

set -eu

SBOM="$1"
shift

if [ ! -s "$SBOM" ]; then
  echo "The SBOM ${SBOM} is missing or empty." >&2
  exit 1
fi

STATUS=0

for PURL in "$@"; do
  case "$PURL" in
    !*)
      if grep -qF "\"${PURL#!}@" "$SBOM"; then
        echo "The SBOM ${SBOM} lists ${PURL#!}, which must not ship." >&2
        STATUS=1
      fi
      ;;
    *)
      if ! grep -qF "\"${PURL}@" "$SBOM"; then
        echo "The SBOM ${SBOM} lacks ${PURL}." >&2
        STATUS=1
      fi
      ;;
  esac
done

if [ "$STATUS" -eq 0 ]; then
  echo "The SBOM ${SBOM} lists the expected packages."
fi

exit "$STATUS"
