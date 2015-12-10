#!/bin/bash
set -e

if zammad config:get DATABASE_URL ; then
    zammad run rake db:migrate
fi

touch tmp/restart.txt

exit 0
