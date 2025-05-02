#!/bin/bash
set -e

shopt -s nullglob

for zip in plugins/*.zip; do
  plugin=$(basename "$zip")
  slug="${plugin%.zip}"
	echo "Installing $slug..."
	docker compose run --rm wpcli wp plugin install /plugins/"$plugin" --activate
done
