#!/usr/bin/bash

set -ex

apt-get update && apt-get dist-upgrade -y
apt-get install -y systemd systemd-sysv
rm -f /usr/sbin/policy-rc.d

apt-get install -y curl gnupg2
echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
  tee -a /etc/apt/sources.list.d/elastic-7.x.list > /dev/null
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  gpg --dearmor | tee /etc/apt/trusted.gpg.d/elasticsearch.gpg> /dev/null
apt-get update
apt-get -y install elasticsearch

curl -1sLf https://dl.packager.io/srv/zammad/zammad/key | \
  gpg --dearmor -o /usr/share/keyrings/zammad-archive-keyring.gpg