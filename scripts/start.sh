#!/bin/bash

docker image rm handsonarchitects/memcached-api
docker image rm handsonarchitects/memcached-sidecar

docker build -t handsonarchitects/memcached-api -f ./modules/cache-api/Dockerfile ./modules/cache-api
docker build -t handsonarchitects/memcached-sidecar -f ./modules/memcached-sidecar/Dockerfile ./modules/memcached-sidecar

helm install memcached-cluster \
  --set architecture="high-availability" \
  --set replicaCount=2 \
  oci://registry-1.docker.io/bitnamicharts/memcached

kubectl apply -f k8s/memcached-api-deployment.yaml
kubectl apply -f k8s/memcached-api-service.yaml

kubectl rollout status deployment/memcached-api -w