import signal
from types import FrameType
from typing import TYPE_CHECKING, Protocol, Any
import functools
import uvloop
import asyncio
from asyncio import AbstractEventLoop
import logging

if TYPE_CHECKING:

    class LambdaContext(Protocol):
        aws_request_id: str
        function_name: str
        function_version: str
        invoked_function_arn: str
        memory_limit_in_mb: int
        log_group_name: str
        log_stream_name: str

        def get_remaining_time_in_millis(self) -> int: ...


logger = logging.getLogger(__name__)


@functools.cache
def get_event_loop() -> AbstractEventLoop:
    loop: AbstractEventLoop = uvloop.new_event_loop()
    logger.error("Creating event loop")
    asyncio.set_event_loop(loop)
    return asyncio.new_event_loop()


async def handle_event(event: Any, context: LambdaContext) -> dict:
    logger.error("Handling event: %s", event)
    return {"statusCode": 200, "body": "Hello, World!"}


async def shutdown(loop: AbstractEventLoop, sig: signal.Signals) -> None:
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]

    [task.cancel() for task in tasks]

    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()


def handler(event: Any, context: LambdaContext) -> dict:
    loop = get_event_loop()
    return loop.run_until_complete(handle_event(event, context))


def signal_handler(signum: int, _frame: FrameType | None = None) -> None:
    loop = get_event_loop()
    loop.run_until_complete(shutdown(loop, signal.Signals(signum)))


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)
