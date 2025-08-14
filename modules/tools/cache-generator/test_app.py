import os
from unittest.mock import MagicMock, patch

import pytest

from app import main


def test_main_with_completion_index_0_batch_size_10() -> None:
    """Test main function with completion_index=0 and batch_size=10 (keys 0-9)"""
    with patch.dict(os.environ, {"JOB_COMPLETION_INDEX": "0", "BATCH_SIZE": "10"}):
        with patch("app.requests.post") as mock_post:
            # Mock successful POST requests
            mock_post.return_value.raise_for_status = MagicMock()

            # Should not raise any exceptions
            main()

            # Verify POST requests were made 10 times (batch_size=10)
            assert mock_post.call_count == 10

            # Verify that keys are in range 0-9 (completion_index=0 * batch_size=10)
            expected_keys = [str(i) for i in range(0, 10)]  # 0, 1, 2, ..., 9
            actual_calls = mock_post.call_args_list

            for i, call in enumerate(actual_calls):
                # Extract the payload from the call
                args, kwargs = call
                payload = kwargs["json"]
                expected_key = expected_keys[i]

                assert payload["key"] == expected_key, f"Expected key {expected_key}, got {payload['key']}"
                assert payload["value"] == "my-value", f"Expected value 'my-value', got {payload['value']}"


def test_main_with_completion_index_1_batch_size_10() -> None:
    """Test main function with completion_index=1 and batch_size=10 (keys 10-19)"""
    with patch.dict(os.environ, {"JOB_COMPLETION_INDEX": "1", "BATCH_SIZE": "10"}):
        with patch("app.requests.post") as mock_post:
            # Mock successful POST requests
            mock_post.return_value.raise_for_status = MagicMock()

            # Should not raise any exceptions
            main()

            # Verify POST requests were made 10 times (batch_size=10)
            assert mock_post.call_count == 10

            # Verify that keys are in range 10-19 (completion_index=1 * batch_size=10)
            expected_keys = [str(i) for i in range(10, 20)]  # 10, 11, 12, ..., 19
            actual_calls = mock_post.call_args_list

            for i, call in enumerate(actual_calls):
                # Extract the payload from the call
                args, kwargs = call
                payload = kwargs["json"]
                expected_key = expected_keys[i]

                assert payload["key"] == expected_key, f"Expected key {expected_key}, got {payload['key']}"
                assert payload["value"] == "my-value", f"Expected value 'my-value', got {payload['value']}"


def test_main_with_invalid_job_completion_index() -> None:
    """Test main function with invalid JOB_COMPLETION_INDEX"""
    with patch.dict(os.environ, {"JOB_COMPLETION_INDEX": "invalid", "BATCH_SIZE": "1"}):
        with pytest.raises(SystemExit):
            main()


def test_main_with_invalid_batch_size() -> None:
    """Test main function with invalid BATCH_SIZE"""
    with patch.dict(os.environ, {"JOB_COMPLETION_INDEX": "0", "BATCH_SIZE": "invalid"}):
        with pytest.raises(SystemExit):
            main()


def test_main_with_missing_environment() -> None:
    """Test main function with missing environment variables"""
    with patch.dict(os.environ, {}, clear=True):
        with pytest.raises(SystemExit):
            main()
