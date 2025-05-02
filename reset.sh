#!/bin/bash

docker compose down --remove-orphans

sudo rm -rf public_html
mkdir public_html

sudo rm -rf db
mkdir	db
