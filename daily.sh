#!/bin/bash

# Unofficial bash strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eu
set -o pipefail
IFS=$'\n\t'

PATH="/usr/local/bin:$PATH"

function finish {

  echo "Stopping database..."
  docker-compose --file=$(pwd)/docker-compose.yml stop db
  docker-compose --file=$(pwd)/docker-compose.yml stop redis

}

trap finish EXIT

echo "==================="
date
echo ""

echo "Starting database..."
docker-compose --file=$(pwd)/docker-compose.yml up -d db
docker-compose --file=$(pwd)/docker-compose.yml up -d redis
sleep 20

echo "Running daily task..."
docker-compose --file=$(pwd)/docker-compose.yml run --rm main rake daily

echo "Backing up raw data..."
docker-compose --file=$(pwd)/docker-compose.yml run --rm pg_dump --format=p --verbose --encoding=UTF-8 --no-owner --no-privileges --inserts --dbname=compta_development --file="/dropbox/backups/$(date +%d).sql"


echo "Notify Deadmansnitch..."
curl "https://nosnch.in/2f07697414"
