#!/bin/bash

set -ex

# create init scripts
/usr/bin/zammad scale web=1 websocket=1 worker=1

# start zammad
systemctl start zammad

# start nginx
systemctl start nginx

