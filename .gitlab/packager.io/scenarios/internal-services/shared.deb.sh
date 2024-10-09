#!/usr/bin/bash

set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

apt-get install -y --reinstall zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"