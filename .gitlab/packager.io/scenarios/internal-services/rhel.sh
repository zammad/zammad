#!/usr/bin/bash

set -eu

dnf install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

dnf reinstall -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"
