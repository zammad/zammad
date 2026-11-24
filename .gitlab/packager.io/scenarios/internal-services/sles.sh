#!/usr/bin/bash

set -eu

zypper install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

zypper install -y -f zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

bash "$(dirname "$0")/shared.sbom.sh"

# Backup script does not work on SLES out of the box, so we cannot test it.
