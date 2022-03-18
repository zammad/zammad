#!/bin/bash

set -o errexit
set -o pipefail

docker build --no-cache -t zammad/svg-icons-build:latest .

docker run --rm -v "$(pwd)/:/tmp/gulp" zammad/svg-icons-build:latest
