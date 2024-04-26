FROM node:20-slim as node


FROM ruby:3.2.4-slim AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG RAILS_ENV=production
ARG ZAMMAD_DIR=/opt/zammad
COPY --from=node /opt /opt
COPY --from=node /usr/local/bin /usr/local/bin
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
WORKDIR ${ZAMMAD_DIR}
COPY . .
RUN contrib/docker/setup.sh builder


# note: zammad is currently incompatible to alpine because of:
# https://github.com/docker-library/ruby/issues/113
FROM ruby:3.2.4-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG ZAMMAD_USER=zammad
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV ZAMMAD_DIR=/opt/zammad
WORKDIR ${ZAMMAD_DIR}
COPY --from=builder ${ZAMMAD_DIR} .
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder ${ZAMMAD_DIR}/contrib/docker/docker-entrypoint.sh /
RUN contrib/docker/setup.sh runner
USER zammad:zammad
ENTRYPOINT ["/docker-entrypoint.sh"]
