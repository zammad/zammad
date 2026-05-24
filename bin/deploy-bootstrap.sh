#!/usr/bin/env bash
#
# deploy-bootstrap.sh — first-time bring-up of the production Zammad stack.
#
#   - Generates deploy/.env from deploy/.env.example if it doesn't exist
#   - Fills SECRET_KEY_BASE and POSTGRESQL_PASS with random values
#   - Builds the image
#   - Brings the stack up
#   - Tails the init container so you can watch the schema get created
#
# Subsequent operations (start / stop / upgrade) — use docker compose directly.
# See deploy/README.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_ROOT}/deploy/.env"
COMPOSE_FILE="${REPO_ROOT}/deploy/docker-compose.yml"

cd "${REPO_ROOT}"

# 1. Pre-flight ---------------------------------------------------------------

command -v docker >/dev/null || { echo "docker is required"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "docker compose v2 is required"; exit 1; }

# 2. Generate .env if missing -------------------------------------------------

if [[ -f "${ENV_FILE}" ]]; then
  echo "==> deploy/.env already exists — leaving it alone."
else
  echo "==> Generating deploy/.env from deploy/.env.example..."
  cp "${REPO_ROOT}/deploy/.env.example" "${ENV_FILE}"

  SECRET_KEY_BASE="$(openssl rand -hex 64)"
  POSTGRES_PASS="$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-32)"

  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s|REPLACE_ME_WITH_openssl_rand_hex_64|${SECRET_KEY_BASE}|" "${ENV_FILE}"
    sed -i '' "s|REPLACE_ME_WITH_RANDOM_PASSWORD|${POSTGRES_PASS}|"        "${ENV_FILE}"
  else
    sed -i    "s|REPLACE_ME_WITH_openssl_rand_hex_64|${SECRET_KEY_BASE}|" "${ENV_FILE}"
    sed -i    "s|REPLACE_ME_WITH_RANDOM_PASSWORD|${POSTGRES_PASS}|"        "${ENV_FILE}"
  fi

  chmod 600 "${ENV_FILE}"
  echo "==> Generated random SECRET_KEY_BASE + POSTGRESQL_PASS."
  echo "    Edit ${ENV_FILE} now to set ZAMMAD_FQDN / ZAMMAD_HTTP_TYPE before continuing."
  echo
  read -r -p "Press ENTER once you've reviewed deploy/.env, or Ctrl-C to abort..."
fi

# 3. Build + bring up ---------------------------------------------------------

echo "==> Building image (this can take 5-10 minutes the first time)..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" build

echo "==> Bringing up Postgres + init..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d zammad-postgresql

# Wait for postgres ready
echo "==> Waiting for Postgres to accept connections..."
until docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T zammad-postgresql pg_isready -q; do
  sleep 1
done

echo "==> Running zammad-init (db:create / db:migrate / db:seed)..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up --no-deps zammad-init

echo "==> Applying env-driven settings (fqdn, http_type, branding)..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up --no-deps zammad-config

echo "==> Starting the app containers..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d \
  zammad-railsserver zammad-scheduler zammad-websocket zammad-nginx zammad-backup

echo
echo "==> Done. Stack status:"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps

cat <<EOF

Next steps:
  - Open http://localhost:\$(grep ^ZAMMAD_HOST_PORT "${ENV_FILE}" | cut -d= -f2) in your browser
  - First admin login: use the auto-wizard at /#getting_started (no users exist yet)
  - To change settings later:
      docker compose --env-file deploy/.env -f deploy/docker-compose.yml exec zammad-railsserver bundle exec rails c
  - To take an ad-hoc backup:
      docker compose --env-file deploy/.env -f deploy/docker-compose.yml run --rm zammad-backup
  - To see logs:
      docker compose --env-file deploy/.env -f deploy/docker-compose.yml logs -f zammad-railsserver

EOF
