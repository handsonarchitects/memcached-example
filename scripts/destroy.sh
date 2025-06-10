#!/bin/bash

helm uninstall memcached-cluster
kubectl delete -f k8s/memcached-api-deployment.yaml
kubectl delete -f k8s/memcached-api-service.yaml
kubectl delete -f k8s/tools-cache-generator-job.yaml