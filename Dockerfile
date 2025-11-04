# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.7
ARG NODE_VERSION=22

FROM docker.io/library/ruby:$RUBY_VERSION-slim-trixie AS base

# Rails app lives here
WORKDIR /opt/zammad

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="test development" \
    RAILS_LOG_TO_STDOUT="true"

# Install base packages
# Add official PostgreSQL apt repository to not depend on Debian's version. https://www.postgresql.org/download/linux/debian/ \
RUN apt-get update -qq && \
    apt-get install -y postgresql-common && \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    apt-get install --no-install-recommends -y curl libimlib2 libpq5 nginx gnupg postgresql-client-17 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Throw-away stage to get the node binary
FROM node:${NODE_VERSION}-trixie-slim AS node
RUN npm -g install corepack && corepack enable pnpm && \
    rm /usr/local/bin/yarn /usr/local/bin/yarnpkg

# Throw-away build stage to reduce size of final image
FROM base AS build

ARG COMMIT_SHA

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libimlib2-dev libpq-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock vendor ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install JavaScript dependencies
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin /usr/local/bin

# Install node modules
COPY package.json pnpm-lock.yaml ./
COPY .eslint-plugin-zammad/package.json .eslint-plugin-zammad/pnpm-lock.yaml .eslint-plugin-zammad/lib/ .eslint-plugin-zammad/
RUN pnpm install --frozen-lockfile

# Copy application code
COPY . .

# Append build information to the Zammad VERSION.
RUN if [ -z "${COMMIT_SHA}" ]; then \
    echo "Error: the required build argument \$COMMIT_SHA is missing."; \
    exit 1; \
  fi; \
  COMMIT_SHA_SHORT=$(echo "${COMMIT_SHA}" | cut -c 1-8); \
  echo "$(tr -d '\n' < VERSION)-${COMMIT_SHA_SHORT}.docker" > VERSION; \
  echo 'Updated build information in VERSION:'; \
  cat VERSION

# Don't require Redis or Postgres.
RUN touch db/schema.rb && \
    ZAMMAD_SAFE_MODE=1 DATABASE_URL=postgresql://zammad:/zammad bundle exec rake assets:precompile

RUN script/build/cleanup.sh

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Final stage for app image
FROM base

# Application variables with defaults matching the Zammad docker stack.
ENV POSTGRESQL_DB=zammad_production \
    POSTGRESQL_HOST=zammad-postgresql \
    POSTGRESQL_PORT=5432 \
    POSTGRESQL_USER=zammad \
    POSTGRESQL_PASS=zammad \
    POSTGRESQL_OPTIONS=?pool=50 \
    RAILS_TRUSTED_PROXIES=127.0.0.1,::1

RUN groupadd --system --gid 1000 zammad && \
  useradd --create-home --home /opt/zammad --shell /bin/bash --uid 1000 --gid 1000 zammad

RUN sed -i -e "s#user www-data;##g" \
           -e 's#/var/log/nginx/\(access\|error\).log#/dev/stdout#g' \
           -e 's#pid /run/nginx.pid;#pid /tmp/nginx.pid;#g' /etc/nginx/nginx.conf && \
  mkdir -p /opt/zammad /var/log/nginx

# Pre-create the storage/ and tmp/ folders to avoid mount permission issues (see https://github.com/zammad/zammad/issues/5412).
RUN mkdir -p "/opt/zammad/storage" "/opt/zammad/tmp" && \
  chown -R 1000:1000 /etc/nginx /var/lib/nginx /var/log/nginx /opt/zammad

# Copy built artifacts: gems, application
COPY --chown=1000:1000 --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=1000:1000 --from=build /opt/zammad /opt/zammad
# Backwards compatibility for older images that used /docker-entrypoint.sh
RUN ln -s "/opt/zammad/bin/docker-entrypoint" /docker-entrypoint.sh

# Run and own only the runtime files as a non-root user for security
USER 1000:1000
ENTRYPOINT ["/opt/zammad/bin/docker-entrypoint"]

# Set labels to help portainer.io admins to access rails console.
LABEL io.portainer.commands.rails-console="bundle exec rails c"
