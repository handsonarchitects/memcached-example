#!/bin/bash
set -e
echo "Generating load for the memcached API service..."

if ! [[ "$JOB_COMPLETION_INDEX" =~ ^[0-9]+$ ]]; then
    echo "JOB_COMPLETION_INDEX must be a positive integer."
    exit 1
fi

if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]]; then
    echo "BATCH_SIZE must be a positive integer."
    exit 1
fi

from=$(($JOB_COMPLETION_INDEX * $BATCH_SIZE))
to=$(($from + $BATCH_SIZE - 1))

echo "Generating load from $from to $to..."

for i in $(seq $from $to); do
    # Check if the memcached API service is running
    if ! curl -s http://memcached-api:8000/health > /dev/null; then
        echo "Memcached API service is not running. Please start the service first."
        exit 1
    fi
    if ! curl -X POST -H "Content-Type: application/json" -d "{\"key\": \"${i}\", \"value\": \"my-value\"}" http://memcached-api:8000/items/ > /dev/null; then
        echo "Failed to send request to memcached API service. Please check if the service is running."
        exit 1
    fi
done

echo "Load generation completed successfully."