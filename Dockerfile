FROM node:20-bookworm-slim AS node
RUN npm -g install corepack && corepack enable pnpm
RUN rm /usr/local/bin/yarn /usr/local/bin/yarnpkg


FROM ruby:3.2.8-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
ARG RAILS_ENV=production
ARG ZAMMAD_DIR=/opt/zammad
ARG COMMIT_SHA
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin /usr/local/bin
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
WORKDIR ${ZAMMAD_DIR}
COPY . .
RUN contrib/docker/setup.sh builder


# note: zammad is currently incompatible to alpine because of:
# https://github.com/docker-library/ruby/issues/113
FROM ruby:3.2.8-slim-bookworm
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

# Set labels to help portainer.io admins to access the shell and rails console.
LABEL io.portainer.commands.bash-via-entrypoint="/docker-entrypoint.sh /bin/bash"
LABEL io.portainer.commands.rails-console="/docker-entrypoint.sh bundle exec rails c"