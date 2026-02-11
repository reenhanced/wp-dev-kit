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

site_url=""
if site_url=$(npx wp-env run cli wp option get siteurl 2>/dev/null); then
  site_url="${site_url//$'\r'/}"
fi

admin_users=""
if admin_users=$(npx wp-env run cli wp user list --role=administrator --field=user_login 2>/dev/null | tr -d '\r' | paste -sd ', ' -); then
  admin_users=${admin_users%, }
fi

echo "Environment is ready."
echo ""
echo "🎉 WordPress is running via wp-env"
if [[ -n "$site_url" ]]; then
  echo "🔗 Site URL: $site_url"
fi
if [[ -n "$admin_users" ]]; then
  echo "👤 Admin users: $admin_users"
fi
echo "ℹ️  Update credentials or URL anytime by rerunning ./setup.sh or editing .wp-env.override.json."
