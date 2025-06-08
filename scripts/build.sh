#!/bin/bash

docker image rm handsonarchitects/memcached-api
docker image rm handsonarchitects/memcached-sidecar

docker build -t handsonarchitects/memcached-api -f ./modules/api/Dockerfile ./modules/api
docker build -t handsonarchitects/memcached-sidecar -f ./modules/memcached-sidecar/Dockerfile ./modules/memcached-sidecar