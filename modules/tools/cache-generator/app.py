#!/usr/bin/env python3

import logging
import os
import re
import sys

import requests

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


def main() -> None:
    logger.info("Generating load for the memcached API service...")

    # Get environment variables
    job_completion_index_str = os.environ.get("JOB_COMPLETION_INDEX")
    batch_size_str = os.environ.get("BATCH_SIZE")

    # Validate JOB_COMPLETION_INDEX
    if not job_completion_index_str or not re.match(r"^[0-9]+$", job_completion_index_str):
        logger.error("JOB_COMPLETION_INDEX must be a positive integer.")
        sys.exit(1)

    # Validate BATCH_SIZE
    if not batch_size_str or not re.match(r"^[0-9]+$", batch_size_str):
        logger.error("BATCH_SIZE must be a positive integer.")
        sys.exit(1)

    # Convert to integers
    job_completion_index: int = int(job_completion_index_str)
    batch_size: int = int(batch_size_str)

    # Calculate range
    from_index: int = job_completion_index * batch_size
    to_index: int = from_index + batch_size - 1

    logger.info(f"Generating load from {from_index} to {to_index}...")

    # Generate load
    for i in range(from_index, to_index + 1):
        # Send POST request
        try:
            payload = {"key": str(i), "value": "my-value"}
            response = requests.post(
                "http://memcached-api:8000/items/",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=5,
            )
            response.raise_for_status()
        except requests.RequestException:
            logger.error("Failed to send request to memcached API service. Please check if the service is running.")
            sys.exit(1)

    logger.info("Load generation completed successfully.")


if __name__ == "__main__":
    main()
