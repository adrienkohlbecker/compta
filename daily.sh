#!/bin/bash

# Unofficial bash strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eu
set -o pipefail
IFS=$'\n\t'

function finish {

  echo "Starting dropbox..."
  open -a Dropbox

  echo "Stopping database..."
  /usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml stop db
  /usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml stop redis

}

trap finish EXIT

echo "==================="
date
echo ""

echo "stopping Dropbox"
killall Dropbox

echo "Starting database..."
/usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml up -d db
/usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml up -d redis
sleep 20

echo "Running daily task..."
/usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml run --rm main rake daily

echo "Backing up raw data..."
/usr/local/bin/docker-compose --file=/Users/ak/Desktop/compta/docker-compose.yml run --rm pg_dump --format=p --verbose --encoding=UTF-8 --no-owner --no-privileges --inserts --dbname=compta_development --file="/dropbox/backups/$(date +%d).sql"


echo "Notify Deadmansnitch..."
curl "https://nosnch.in/2f07697414"
