#!/bin/bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
	echo "npx is required to reset the environment." >&2
	exit 1
fi

echo "Destroying wp-env environment..."
npx wp-env destroy --hard

echo "Resetting local content directories..."
rm -rf public_html/wp-content
mkdir -p public_html/wp-content
touch public_html/.keep
touch public_html/wp-content/.keep

rm -rf db
mkdir -p db
touch db/.keep
