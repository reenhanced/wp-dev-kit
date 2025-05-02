#!/bin/bash
set -e

# Load the environment variables, used for build
export $(grep -v '^#' .env | xargs)

echo "Starting containers..."
docker compose up -d

echo "Waiting for the database to be ready..."
until docker compose exec mysql mysqladmin ping -h"localhost" --silent; do
  echo "Database is not ready yet. Waiting..."
  sleep 5
done

echo "Waiting for WordPress to be ready..."
until docker compose run --rm wpcli wp core is-installed > /dev/null 2>&1; do
  echo "WordPress is not installed. Installing..."
  docker compose run --rm wpcli wp core install \
    --url="https://${WP_HOME}" \
    --title="My WordPress Site" \
    --admin_user="${WORDPRESS_ADMIN_USER}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL}"
  sleep 5
done

echo "Installing plugins..."
./install_plugins.sh

echo "Build process finished."
echo ""
echo "🎉 WordPress is ready!"
echo "🔗 Admin Panel: https://${WP_HOME}/wp-admin/"
echo "👤 Username: ${WORDPRESS_ADMIN_USER}"
echo "🔑 Password: ${WORDPRESS_ADMIN_PASSWORD}"
