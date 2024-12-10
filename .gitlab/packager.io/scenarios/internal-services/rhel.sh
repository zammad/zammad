#!/usr/bin/bash

set -eu

# Workaround: postgresql fails on rhel-9 when it gets installed together with Zammad.
dnf install -y postgresql-server

dnf install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

dnf reinstall -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"
