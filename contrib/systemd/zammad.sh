#!/bin/bash
#
# enable zammad systemd services
#

if [ "$(whoami)" != 'root' ]; then
  echo "you need to be root to run this script!"
  exit 1
fi

cp zammad.service zammad-rails.service zammad-scheduler.service zammad-websocket.service /etc/systemd/system

systemctl daemon-reload

systemctl enable zammad

systemctl start zammad
