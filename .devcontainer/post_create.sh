#!/usr/bin/env sh

env

# Ensure proper permissions on root-mounted volume.
sudo chown -R "${USER}" node_modules

bin/setup --skip-server

bundle exec bootsnap precompile --gemfile app/ lib/

bundle exec rails r "Setting.set('es_url', 'http://elasticsearch:9200')"

bundle exec rails zammad:setup:auto_wizard

echo "== LAUNCHING ZAMMAD =="
echo "1. Close this terminal by hitting \`Enter\`"
echo "2. Open a new terminal via \`VS Code\` to attach to devcontainer shell"
echo "3. Run to start develoment services inside devcontainer:"
echo "\`\`\`"
echo "bin/dev"
echo "\`\`\`"
