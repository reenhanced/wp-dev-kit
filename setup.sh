#!/bin/bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "This script requires Node.js (npx) to be installed." >&2
  exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ---------------------------------------------------------------------------
# Port availability helper
# ---------------------------------------------------------------------------
port_in_use() {
  # Returns 0 (true) if a process is listening on the given TCP port.
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | grep -qE ":${1}\b"
  elif command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$1" -sTCP:LISTEN -P -n >/dev/null 2>&1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln 2>/dev/null | grep -qE ":${1}\b"
  else
    return 1  # assume available when we cannot check
  fi
}

find_available_port() {
  local candidate=$1
  while port_in_use "$candidate"; do
    candidate=$((candidate + 1))
  done
  echo "$candidate"
}

base_port=8067
default_port=$(find_available_port $base_port)
default_url="http://localhost:${default_port}"
default_admin_user="admin"
default_admin_pass="password"
default_debug_log="wp-content/debug.log"

read -rp "Do you want to enable multisite? (y/N): " multisite_choice
multisite_choice=${multisite_choice:-N}
multisite_choice=$(printf '%s' "$multisite_choice" | tr '[:upper:]' '[:lower:]')

read -rp "Do you want to enable debugging? (Y/n): " debug_choice
debug_choice=${debug_choice:-Y}
debug_choice=$(printf '%s' "$debug_choice" | tr '[:upper:]' '[:lower:]')

read -rp "Where should the debug log be stored? [$default_debug_log]: " debug_log_path
debug_log_path=${debug_log_path:-$default_debug_log}

read -rp "What URL should this site use? [$default_url]: " site_url
site_url=${site_url:-$default_url}
site_url=${site_url%/}

while true; do
  if [[ $default_port -ne $base_port ]]; then
    echo "Note: Port $base_port is already in use; suggesting $default_port instead."
  fi
  read -rp "Which port should expose WordPress? [$default_port]: " port_choice
  port_choice=${port_choice:-$default_port}
  if ! [[ $port_choice =~ ^[0-9]+$ ]]; then
    echo "Please provide a numeric port." >&2
    continue
  fi
  if port_in_use "$port_choice"; then
    echo "Port $port_choice is already in use. Please choose another." >&2
    continue
  fi
  break
done

tests_port=$((port_choice + 1000))

read -rp "Admin username? [$default_admin_user]: " admin_user
admin_user=${admin_user:-$default_admin_user}

read -rsp "Admin password? [$default_admin_pass]: " admin_pass
echo ""
admin_pass=${admin_pass:-$default_admin_pass}

admin_email="${admin_user}@example.com"

# cached choices for templating
debug_enabled="false"
[[ $debug_choice == "y" ]] && debug_enabled="true"

if [[ $multisite_choice == "y" ]]; then
  site_host=$(printf '%s' "$site_url" | sed -E 's#^https?://([^/]+).*#\1#')
  site_path=$(printf '%s' "$site_url" | sed -E 's#^https?://[^/]+(/.*)?$#\1#')
  site_path=${site_path:-/}
  [[ $site_path != */ ]] && site_path="${site_path}/"
fi

if [[ $multisite_choice == "y" ]]; then
  cat > "$repo_root/.wp-env.override.json" <<JSON
{
  "port": $port_choice,
  "testsPort": $tests_port,
  "config": {
    "WP_HOME": "$site_url",
    "WP_SITEURL": "$site_url",
    "WP_DEBUG": $debug_enabled,
    "WP_DEBUG_DISPLAY": false,
    "WP_DEBUG_LOG": "$debug_log_path",
    "WP_ALLOW_MULTISITE": true,
    "MULTISITE": true,
    "SUBDOMAIN_INSTALL": false,
    "DOMAIN_CURRENT_SITE": "$site_host",
    "PATH_CURRENT_SITE": "$site_path",
    "SITE_ID_CURRENT_SITE": 1,
    "BLOG_ID_CURRENT_SITE": 1
  }
}
JSON
else
  cat > "$repo_root/.wp-env.override.json" <<JSON
{
  "port": $port_choice,
  "testsPort": $tests_port,
  "config": {
    "WP_HOME": "$site_url",
    "WP_SITEURL": "$site_url",
    "WP_DEBUG": $debug_enabled,
    "WP_DEBUG_DISPLAY": false,
    "WP_DEBUG_LOG": "$debug_log_path"
  }
}
JSON
fi

mkdir -p "$repo_root/.wp-env"

override_compose="$repo_root/.wp-env/docker-compose.override.yml"
if [[ ! -f "$override_compose" ]]; then
  cat > "$override_compose" <<'YAML'
# This override file lets you add machine-specific Docker customisations for wp-env.
# Uncomment the examples below to add labels, extra environment variables, or mounts.
services:
  wordpress:
    # environment:
    #   MY_CUSTOM_ENV: some-value
    # labels:
    #   traefik.enable: "true"
    #   traefik.http.routers.wp-dev-kit.rule: Host(`example.local`)
    # volumes:
    #   - ./relative/path:/container/path

# Add additional services here if you need supporting infrastructure.
# This file is gitignored; keep secrets here rather than in tracked config.
YAML
fi

npx wp-env start

if npx wp-env run cli wp core is-installed >/dev/null 2>&1; then
  echo ""
  echo "This environment already has WordPress installed."
  echo "If you intended a fresh install, run 'npx wp-env destroy --hard' first and rerun setup.sh."
else
  echo "Installing WordPress with your chosen settings..."
  if [[ $multisite_choice == "y" ]]; then
    npx wp-env run cli wp core multisite-install \
      --url="$site_url" \
      --title="WordPress" \
      --admin_user="$admin_user" \
      --admin_password="$admin_pass" \
      --admin_email="$admin_email" \
      --skip-email >/dev/null
  else
    npx wp-env run cli wp core install \
      --url="$site_url" \
      --title="WordPress" \
      --admin_user="$admin_user" \
      --admin_password="$admin_pass" \
      --admin_email="$admin_email" \
      --skip-email >/dev/null
  fi
fi

echo ""
echo "Environment ready!"
echo "URL: $site_url"
echo "Port: $port_choice (tests port: $tests_port)"
echo "Admin user: $admin_user"
echo "Multisite: $( [[ $multisite_choice == "y" ]] && echo "enabled" || echo "disabled" )"
echo "Debugging: $( [[ $debug_choice == "y" ]] && echo "enabled" || echo "disabled" ) (log: $debug_log_path)"
echo ""
echo "To customize environment variables or Docker labels, edit .wp-env/docker-compose.override.yml."
echo "Local-only config lives in .wp-env.override.json."
