#!/usr/bin/bash

set -eu

# Reports "degraded" inside containers, which is fine once boot has finished.
systemctl is-system-running --wait || true

dnf install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

dnf reinstall -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

# Backup script does not work on RHEL out of the box, so we cannot test it.
