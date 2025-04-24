#!/bin/bash
set -e

PLUGINS=(
  "ingest-attachment"
  # Add more here if needed in future
)

for plugin in "${PLUGINS[@]}"; do
  if ! elasticsearch-plugin list | grep -q "$plugin"; then
    echo "Installing plugin: $plugin"
    elasticsearch-plugin install --batch "$plugin"
  else
    echo "Plugin already installed: $plugin"
  fi
done
