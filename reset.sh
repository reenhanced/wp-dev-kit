#!/bin/bash

docker compose down --remove-orphans

sudo rm -rf public_html
mkdir public_html
touch public_html/.keep

sudo rm -rf db
mkdir	db
touch db/.keep
