#!/bin/bash

set -o errexit
set -o pipefail

docker build --no-cache -t zammad/smime-test-certificates:latest .

docker run --rm -v `pwd`/../:/etc/ssl/certs zammad/smime-test-certificates:latest

