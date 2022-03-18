FROM node:8-alpine

ENV GULP_DIR "/tmp/gulp"

RUN apk update && apk add bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
CMD bash # If you want to override CMD
RUN npm install -g gulp

COPY docker-entrypoint.sh /

# enable volume to generate build files into the hosts FS
VOLUME ["$GULP_DIR"]

# start
ENTRYPOINT ["/docker-entrypoint.sh"]
