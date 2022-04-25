#!/bin/bash

set -o errexit
set -o pipefail

docker build --platform amd64 --no-cache -t zammad/chat-build:latest .

docker run --rm -v "$(pwd)/:/tmp/gulp" zammad/chat-build:latest
