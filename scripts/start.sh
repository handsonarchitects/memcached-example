#!/bin/bash

helm install memcached-cluster \
  --set architecture="high-availability" \
  --set replicaCount=2 \
  oci://registry-1.docker.io/bitnamicharts/memcached

kubectl apply -f k8s/memcached-api-deployment.yaml
kubectl apply -f k8s/memcached-api-service.yaml

kubectl rollout status deployment/memcached-api -w