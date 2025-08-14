#!/t/venv/rq/bin/python

from redis_streams_test.client import TestClient
from redis_streams_test.exceptions import JobError

# Initialize test client with namespace
client = TestClient("stardate")

# Clean up any existing messages
print("\nCleaning up streams before testing...")
client.cleanup_streams()

def run_test(name, command, args):
    """Helper function to run a test and print results"""
    print(f"\nTesting {name}:")
    try:
        job_id = client.enqueue_job(client.get_request_stream(), command, args)
        print(f"Enqueued {command} job with ID: {job_id}")
        result = client.get_job_result(client.get_response_stream(), job_id)
        print("Result:", result)
        return result
    except JobError as e:
        print("Error:", str(e))
        return None

# Test to_stardate command with current time
now_args = {
    "datetime": "now",
    "format": "medium"
}
run_test("to_stardate command with current time", "to_stardate", now_args)

# Test to_stardate command with specific datetime
datetime_args = {
    "datetime": "2024-01-24 14:00:00",
    "timezone": "America/Los_Angeles",
    "format": "canonical"
}
stardate_result = run_test("to_stardate command with specific datetime", "to_stardate", datetime_args)

if stardate_result:
    stardate = float(stardate_result)

    # Test from_stardate command
    from_args = {
        "stardate1": str(stardate),
        "timezone": "America/Los_Angeles"
    }
    run_test("from_stardate command", "from_stardate", from_args)

    # Test stardate_diff command
    diff_args = {
        "stardate1": str(stardate),
        "stardate2": str(stardate + 0.5),  # About 6 months difference
        "unit": "months"
    }
    run_test("stardate_diff command", "stardate_diff", diff_args)

    # Test stardate_to_unix command
    to_unix_args = {
        "stardate1": str(stardate)
    }
    unix_result = run_test("stardate_to_unix command", "stardate_to_unix", to_unix_args)

    # Test unix_to_stardate command using the result from above
    if unix_result:
        to_stardate_args = {
            "timestamp": str(int(unix_result)),
            "format": "canonical"
        }
        run_test("unix_to_stardate command", "unix_to_stardate", to_stardate_args)

# Test error handling - Missing required argument
missing_args = {
    "format": "medium"  # Missing required datetime argument
}
run_test("error handling - Missing required argument", "to_stardate", missing_args)

# Test error handling - Invalid datetime format
invalid_datetime_args = {
    "datetime": "2024-24-01",  # Invalid date format
    "timezone": "America/Los_Angeles",
    "format": "medium"
}
run_test("error handling - Invalid datetime format", "to_stardate", invalid_datetime_args)

# Test error handling - Invalid timezone
invalid_timezone_args = {
    "datetime": "2024-01-24 14:00:00",
    "timezone": "Invalid/Timezone",  # Invalid timezone
    "format": "medium"
}
run_test("error handling - Invalid timezone", "to_stardate", invalid_timezone_args)

# Clean up after testing
print("\nCleaning up streams after testing...")
client.cleanup_streams()
