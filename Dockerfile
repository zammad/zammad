FROM node:16.18.0-slim as node


FROM ruby:3.1.3-slim AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG RAILS_ENV=production
ARG ZAMMAD_TMP_DIR=/tmp/zammad
COPY --from=node /opt /opt
COPY --from=node /usr/local/bin /usr/local/bin
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
WORKDIR ${ZAMMAD_TMP_DIR}
COPY . .
RUN contrib/docker/setup.sh builder


# note: zammad is currently incompatible to alpine because of:
# https://github.com/docker-library/ruby/issues/113
FROM ruby:3.1.3-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG ZAMMAD_USER=zammad
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV ZAMMAD_DIR=/opt/zammad
ENV ZAMMAD_TMP_DIR=/tmp/zammad
COPY --from=builder ${ZAMMAD_TMP_DIR} ${ZAMMAD_TMP_DIR}
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder ${ZAMMAD_TMP_DIR}/contrib/docker/docker-entrypoint.sh /
WORKDIR ${ZAMMAD_TMP_DIR}
RUN contrib/docker/setup.sh runner
ENTRYPOINT ["/docker-entrypoint.sh"]
USER zammad
WORKDIR ${ZAMMAD_DIR}
