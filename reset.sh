#!/bin/bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
	echo "npx is required to reset the environment." >&2
	exit 1
fi

echo "Destroying wp-env environment..."
if ! npx wp-env destroy --hard 2>/dev/null; then
	echo "wp-env environment not found or already destroyed. Continuing cleanup..."
fi

echo "Resetting local content directories..."
rm -rf public_html/wp-content
mkdir -p public_html/wp-content
touch public_html/.keep
touch public_html/wp-content/.keep

rm -rf db
mkdir -p db
touch db/.keep
