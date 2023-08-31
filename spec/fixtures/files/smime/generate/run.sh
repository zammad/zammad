#!/bin/bash

set -o errexit
set -o pipefail

docker build --no-cache --tag zammad/smime-test-certificates:latest .

docker run --rm --env=FORCE_REGENERATE=${FORCE_REGENERATE:=""} --volume "$(pwd)/../:/etc/ssl/certs" zammad/smime-test-certificates:latest
