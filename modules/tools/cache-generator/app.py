#!/usr/bin/env python3

import os
import sys
import requests
import re
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    logger.info("Generating load for the memcached API service...")
    
    # Get environment variables
    job_completion_index = os.environ.get('JOB_COMPLETION_INDEX')
    batch_size = os.environ.get('BATCH_SIZE')
    
    # Validate JOB_COMPLETION_INDEX
    if not job_completion_index or not re.match(r'^[0-9]+$', job_completion_index):
        logger.error("JOB_COMPLETION_INDEX must be a positive integer.")
        sys.exit(1)
    
    # Validate BATCH_SIZE
    if not batch_size or not re.match(r'^[0-9]+$', batch_size):
        logger.error("BATCH_SIZE must be a positive integer.")
        sys.exit(1)
    
    # Convert to integers
    job_completion_index = int(job_completion_index)
    batch_size = int(batch_size)
    
    # Calculate range
    from_index = job_completion_index * batch_size
    to_index = from_index + batch_size - 1
    
    logger.info(f"Generating load from {from_index} to {to_index}...")
    
    # Generate load
    for i in range(from_index, to_index + 1):
        # Check if the memcached API service is running
        try:
            response = requests.get("http://memcached-api:8000/health", timeout=5)
            response.raise_for_status()
        except requests.RequestException:
            logger.error("Memcached API service is not running. Please start the service first.")
            sys.exit(1)
        
        # Send POST request
        try:
            payload = {"key": str(i), "value": "my-value"}
            response = requests.post(
                "http://memcached-api:8000/items/",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=5
            )
            response.raise_for_status()
        except requests.RequestException:
            logger.error("Failed to send request to memcached API service. Please check if the service is running.")
            sys.exit(1)
    
    logger.info("Load generation completed successfully.")

if __name__ == "__main__":
    main()