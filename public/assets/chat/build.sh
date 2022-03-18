#!/bin/bash

set -o errexit
set -o pipefail

docker build --no-cache -t zammad/chat-build:latest .

docker run --rm -v "$(pwd)/:/tmp/gulp" zammad/chat-build:latest
