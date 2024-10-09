#!/usr/bin/bash

set -eu

zypper update -y

zypper install -y systemd

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md"| tee /etc/zypp/repos.d/elasticsearch-7.x.repo
zypper install -y elasticsearch

rpm --import https://dl.packager.io/srv/zammad/zammad/key

curl -o /etc/zypp/repos.d/zammad.repo \
  https://dl.packager.io/srv/zammad/zammad/${CI_COMMIT_REF_NAME}/installer/sles/${DISTRIBUTION_VERSION}.repo

zypper update -y
zypper install -y --download-only zammad