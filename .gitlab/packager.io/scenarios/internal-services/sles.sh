#!/usr/bin/bash

set -eu

# special handling for Redis on SuSE
zypper install -y redis7
cp /etc/redis/default.conf.example /etc/redis/zammad.conf
chown root:redis /etc/redis/zammad.conf
systemctl start redis@zammad.service

zypper install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

zypper install -y -f zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"
