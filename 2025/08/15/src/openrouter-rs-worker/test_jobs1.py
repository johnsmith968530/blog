#!/t/venv/rq/bin/python

import json
from redis_streams_test.client import TestClient
from redis_streams_test.exceptions import JobError

# Initialize client with namespace
client = TestClient("openrouter")

def run_test(name, command, args=None):
    """Helper function to run a test and print results"""
    print(f"\nTesting {name}:")
    try:
        job_id = client.enqueue_job(client.get_request_stream(), command, args)
        print(f"Enqueued {command} job with ID: {job_id}")
        result = client.get_job_result(client.get_response_stream(), job_id)
        result_json = json.loads(result)
        print("Result:", json.dumps(result_json, indent=2))
        return result_json
    except JobError as e:
        print("Error:", str(e))
        return None

def test_chat_completion_image():
    """Test chat_completion command with image"""
    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "What's in this image?"
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "/home/x/Nextcloud/3/hash/sha/2/256/17/94/28012da5324979132a003887ed74817e4ed161bc81141260ae0072737bfb.png"
                    }
                }
            ]
        }
    ]
    args = {
        "messages": messages,  # Pass as JSON object, not string
        "model": "openai/chatgpt-4o-latest",
        "log": True
    }
    return run_test("chat_completion command with image", "chat_completion", args)

if __name__ == '__main__':
    # Clean up any old messages
    print("Cleaning up streams before testing...")
    client.cleanup_streams()
    
    # Run tests
    test_chat_completion_image()
    
    # Clean up after testing
    print("\nCleaning up streams after testing...")
    client.cleanup_streams()
