#!/bin/bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required to run this script." >&2
  exit 1
fi

echo "Starting wp-env environment..."
npx wp-env start

echo "Waiting for WordPress to finish bootstrapping..."
until npx wp-env run cli wp core is-installed >/dev/null 2>&1; do
  echo "WordPress is not ready yet. Waiting..."
  sleep 5
done

if compgen -G "plugins/*.zip" >/dev/null 2>&1; then
  echo "Installing plugin ZIP packages..."
  ./install_plugins.sh
fi

echo "Environment is ready."
echo ""
echo "🎉 WordPress is running via wp-env"
echo "🔗 Admin Panel: http://localhost:8067/wp-admin/"
echo "👤 Username: admin"
echo "🔑 Password: password"
