#!/bin/bash

set -o errexit
set -o pipefail

docker build -t zammad/smime-test-certificates:latest . #--no-cache 

docker run --rm -v "$(pwd)/../:/etc/ssl/certs" zammad/smime-test-certificates:latest
