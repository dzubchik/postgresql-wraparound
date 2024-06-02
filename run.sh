#!/bin/bash

export VERSION=${VERSION:-13}

docker-compose pull
docker-compose up -d

sleep 5

docker-compose exec postgres sh -c "cd /data && ./prepare.sh && ./test.sh"