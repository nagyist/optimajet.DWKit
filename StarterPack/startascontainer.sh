#!/bin/sh

if ! type docker > /dev/null; then
  echo "Docker not found. Please install Docker to run this application"
  echo "For more information visit https://docs.docker.com/install/"
  exit 127
fi

docker compose up --build dwkit_starterpack
