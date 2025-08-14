import json
import redis
from .config import get_redis_config
from .exceptions import JobError

class TestClient:
    # New namespace functionality
    def __init__(self, namespace):
        host, port, password = get_redis_config()
        self.redis = redis.Redis(host=host, port=port, password=password, db=0)
        self.namespace = namespace

    def enqueue_job(self, stream_name, command, args=None):
        fields = {
            "command": command,
            "args": json.dumps(args) if args else "{}"
        }
        job_id = self.redis.xadd(stream_name, fields=fields)
        return job_id

    def get_timeout(self):
        """Get the timeout value from Redis"""
        timeout = self.redis.get(f"{self.namespace}:timeout")
        if not timeout:
            raise JobError(f"Timeout key '{self.namespace}:timeout' does not exist")
        print(f"{self.namespace}:timeout = {int(timeout)}")
        return int(timeout)

    def get_job_result(self, stream_name, job_id):
        """Get a job result, waiting up to the configured timeout."""
        import time

        # Get timeout at start
        timeout = self.get_timeout()
        start_time = time.time()
        block_ms = 5000  # 5 second blocks, same as Rust implementation

        while True:
            # Check if we've exceeded total timeout
            elapsed = time.time() - start_time
            if elapsed >= timeout:
                raise JobError("Timeout waiting for result")

            # Non-blocking check of existing messages
            messages = self.redis.xrevrange(stream_name, '+', '-')
            for message_id, fields in messages:
                if fields[b'job_id'] == job_id:
                    if b'result' in fields:
                        return fields[b'result'].decode('utf-8')
                    elif b'error' in fields:
                        raise JobError(fields[b'error'].decode('utf-8'))

            # Calculate remaining time for blocking read
            remaining_ms = min(block_ms, int((timeout - elapsed) * 1000))
            
            # Blocking check for new messages
            response = self.redis.xread(
                {stream_name: '$'},  # $ means only new messages
                block=remaining_ms,
                count=1
            )

            if response:
                for stream_name, messages in response:
                    for message_id, fields in messages:
                        if fields[b'job_id'] == job_id:
                            if b'result' in fields:
                                return fields[b'result'].decode('utf-8')
                            elif b'error' in fields:
                                raise JobError(fields[b'error'].decode('utf-8'))

    def get_request_stream(self):
        return f"{self.namespace}:requests"

    def get_response_stream(self):
        return f"{self.namespace}:responses"

    def get_error_stream(self):
        return f"{self.namespace}:errors"

    def cleanup_streams(self):
        """Trim all streams in the namespace to length zero."""
        for stream in [self.get_request_stream(), self.get_response_stream(), self.get_error_stream()]:
            self.redis.xtrim(stream, maxlen=0)
