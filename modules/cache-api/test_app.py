from typing import Any
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app import app

client = TestClient(app)


def test_health_endpoint_returns_healthy_status() -> None:
    """Verify that health endpoint returns 200 OK with healthy status"""
    response = client.get("/health")
    assert response.status_code == 200, "Health endpoint should return 200 OK"
    assert response.json() == {"status": "healthy"}, "Health endpoint should return healthy status in JSON format"


@patch("app.base.Client")
def test_reading_existing_cache_item_returns_value(mock_client: Any) -> None:
    """Verify that reading an existing cache item returns the correct key-value pair"""
    # Mock the memcached client
    mock_instance = MagicMock()
    mock_instance.get.return_value = b"test_value"
    mock_client.return_value = mock_instance

    response = client.get("/items/test_key")
    assert response.status_code == 200
    assert response.json() == {"key": "test_key", "value": "test_value"}


@patch("app.base.Client")
def test_reading_nonexistent_cache_item_returns_error(mock_client: Any) -> None:
    """Verify that reading a non-existent cache item returns 400 status with error message"""
    # Mock the memcached client
    mock_instance = MagicMock()
    mock_instance.get.return_value = None
    mock_client.return_value = mock_instance

    response = client.get("/items/nonexistent_key")
    assert response.status_code == 400
    assert response.json() == {"detail": "Key not found"}


@patch("app.base.Client")
def test_creating_cache_item_returns_success_status(mock_client: Any) -> None:
    """Verify that creating a new cache item returns success status and calls memcached set method"""
    # Mock the memcached client
    mock_instance = MagicMock()
    mock_client.return_value = mock_instance

    response = client.post("/items/", json={"key": "test_key", "value": "test_value"})
    assert response.status_code == 200
    assert response.json() == {"status": "success"}
    mock_instance.set.assert_called_once_with("test_key", "test_value")
