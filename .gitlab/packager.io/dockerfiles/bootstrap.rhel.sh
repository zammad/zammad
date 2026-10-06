#!/usr/bin/bash

set -eu

dnf update -y

dnf install -y systemd epel-release

# A background metadata refresh races with the scenario's dnf calls on the lock file.
systemctl mask dnf-makecache.timer dnf-makecache.service

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md"| tee /etc/yum.repos.d/elasticsearch-8.x.repo
dnf install -y elasticsearch

rpm --import https://go.packager.io/srv/rpm/zammad/zammad/gpg-key.asc

curl -o /etc/yum.repos.d/zammad.repo \
  https://go.packager.io/srv/zammad/zammad/${CI_COMMIT_REF_NAME}/installer/el/${DISTRIBUTION_VERSION}.repo

dnf update -y
dnf install -y --downloadonly zammad