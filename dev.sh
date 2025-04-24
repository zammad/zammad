#!/bin/bash

set -euo pipefail

PROJECT_NAME=zammad-dev
COMPOSE_FILE=".dev/docker-compose.yml"
ENV_FILE=".dev/.env"
ENV_TEMPLATE=".dev/.env.dist"

# Ensure .env exists
if [ ! -f "$ENV_FILE" ]; then
  echo "📝 .env file not found, copying default from .env.dist"
  cp "$ENV_TEMPLATE" "$ENV_FILE"
fi

echo "🧹 Removing previous containers..."
docker-compose -f "$COMPOSE_FILE" down --volumes --remove-orphans || true

echo "🔧 Building and starting containers..."
COMMIT_SHA=$(git rev-parse HEAD) RAILS_ENV=development docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo "⚙️  Running one-shot DB initializer..."
docker compose -f "$COMPOSE_FILE" run --rm zammad zammad-init

echo "✅ Zammad is running at: http://localhost:3000"
