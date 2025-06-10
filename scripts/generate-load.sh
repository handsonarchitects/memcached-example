#!/bin/bash

docker build -t handsonarchitects/tools-cache-generator -f ./modules/tools/cache-generator/Dockerfile ./modules/tools/cache-generator
kubectl apply -f k8s/tools-cache-generator-job.yaml