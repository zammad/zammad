#!/bin/bash
#
# enable zammad systemd services
#

ZAMMAD_ENV_DIR="/etc/zammad"
SYSTEMD_SERVICE_DIR="/etc/systemd/system"

if [ "$(whoami)" != 'root' ]; then
  echo "you need to be root to run this script!"
  exit 1
fi

test -d ${ZAMMAD_ENV_DIR} || mkdir -p ${ZAMMAD_ENV_DIR}

test -d ${SYSTEMD_SERVICE_DIR} || mkdir -p ${SYSTEMD_SERVICE_DIR}

cp zammad.env ${ZAMMAD_ENV_DIR}

cp zammad.service zammad-rails.service zammad-scheduler.service zammad-websocket.service ${SYSTEMD_SERVICE_DIR}

systemctl daemon-reload

systemctl enable zammad

systemctl start zammad
