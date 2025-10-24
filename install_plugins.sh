#!/bin/bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
	echo "npx is required to install plugins." >&2
	exit 1
fi

shopt -s nullglob

for zip in plugins/*.zip; do
	plugin="$(basename "$zip")"
	slug="${plugin%.zip}"
	echo "Installing ${slug}..."
	npx wp-env run cli wp plugin install \
		"/var/www/html/wp-content/wp-dev-kit-packages/${plugin}" --activate
done
