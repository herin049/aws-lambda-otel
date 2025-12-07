import pytest
import asyncio
from unittest.mock import Mock, patch
import signal
from o11ylambda.entrypoints.aws_lambda import (
    handler,
    handle_event,
    get_event_loop,
    shutdown,
)


@pytest.fixture
def mock_context():
    context = Mock()
    context.aws_request_id = "test-request-id"
    context.function_name = "test-function"
    context.function_version = "$LATEST"
    context.invoked_function_arn = (
        "arn:aws:lambda:us-east-1:123456789012:function:test-function"
    )
    context.memory_limit_in_mb = 128
    context.log_group_name = "/aws/lambda/test-function"
    context.log_stream_name = "2024/01/01/[$LATEST]test"
    context.get_remaining_time_in_millis = Mock(return_value=30000)
    return context


@pytest.fixture
def sample_event():
    return {"key1": "value1", "key2": "value2"}


class TestHandleEvent:
    @pytest.mark.asyncio
    async def test_handle_event_returns_success(self, sample_event, mock_context):
        result = await handle_event(sample_event, mock_context)

        assert result["statusCode"] == 200
        assert result["body"] == "Hello, World!"

    @pytest.mark.asyncio
    async def test_handle_event_with_empty_event(self, mock_context):
        result = await handle_event({}, mock_context)

        assert result["statusCode"] == 200
        assert "body" in result


class TestHandler:
    def test_handler_returns_dict(self, sample_event, mock_context):
        result = handler(sample_event, mock_context)

        assert isinstance(result, dict)
        assert "statusCode" in result
        assert "body" in result

    def test_handler_success_response(self, sample_event, mock_context):
        result = handler(sample_event, mock_context)

        assert result["statusCode"] == 200
        assert result["body"] == "Hello, World!"

    def test_handler_with_none_event(self, mock_context):
        result = handler(None, mock_context)

        assert result["statusCode"] == 200


class TestGetEventLoop:
    def test_get_event_loop_returns_loop(self):
        loop = get_event_loop()

        assert isinstance(loop, asyncio.AbstractEventLoop)

    def test_get_event_loop_is_cached(self):
        loop1 = get_event_loop()
        loop2 = get_event_loop()

        assert loop1 is loop2


class TestShutdown:
    @pytest.mark.asyncio
    async def test_shutdown_cancels_tasks(self):
        loop = asyncio.get_event_loop()

        # Create some dummy tasks
        async def dummy_task():
            await asyncio.sleep(10)

        task1 = asyncio.create_task(dummy_task())
        task2 = asyncio.create_task(dummy_task())

        await shutdown(loop, signal.SIGTERM)

        assert task1.cancelled() or task1.done()
        assert task2.cancelled() or task2.done()

    @pytest.mark.asyncio
    async def test_shutdown_with_no_tasks(self):
        loop = asyncio.get_event_loop()

        await shutdown(loop, signal.SIGTERM)


class TestIntegration:
    def test_full_lambda_invocation(self, sample_event, mock_context):
        result = handler(sample_event, mock_context)

        assert result is not None
        assert result["statusCode"] == 200
        assert isinstance(result["body"], str)

    @patch("o11ylambda.entrypoints.aws_lambda.handle_event")
    def test_handler_calls_handle_event(
        self, mock_handle_event, sample_event, mock_context
    ):
        mock_handle_event.return_value = {"statusCode": 200, "body": "Mocked"}

        _ = handler(sample_event, mock_context)
        mock_handle_event.assert_called_once()
