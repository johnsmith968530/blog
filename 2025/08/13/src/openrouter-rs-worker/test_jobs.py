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

def test_list_models():
    """Test list_models command"""
    return run_test("list_models command", "list_models")

def test_chat_completion_text():
    """Test chat_completion command with text only"""
    messages = [
        {
            "role": "user",
            "content": "Hello! How are you?"
        }
    ]
    args = {
        "messages": messages,  # Pass as JSON object, not string
        "log": True
    }
    return run_test("chat_completion command with text only", "chat_completion", args)

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
        "log": True
    }
    return run_test("chat_completion command with image", "chat_completion", args)

def test_chat_completion_model():
    """Test chat_completion command with specific model"""
    messages = [
        {
            "role": "user",
            "content": "Tell me a joke"
        }
    ]
    args = {
        "messages": messages,  # Pass as JSON object, not string
        "model": "anthropic/claude-3-opus",
        "log": True
    }
    return run_test("chat_completion command with specific model", "chat_completion", args)

def test_error_handling():
    """Test various error cases"""
    print("\nTesting error handling:")

    print("\nMissing required argument:")
    args = {
        "log": True  # Missing messages argument
    }
    run_test("missing required argument", "chat_completion", args)

    print("\nInvalid messages format:")
    args = {
        "messages": "not valid json",
        "log": True
    }
    run_test("invalid messages format", "chat_completion", args)

    print("\nUnknown command:")
    run_test("unknown command", "unknown_command")

if __name__ == '__main__':
    # Clean up any old messages
    print("Cleaning up streams before testing...")
    client.cleanup_streams()
    
    # Run tests
    test_list_models()
    test_chat_completion_text()
    test_chat_completion_image()
    test_chat_completion_model()
    test_error_handling()
    
    # Clean up after testing
    print("\nCleaning up streams after testing...")
    client.cleanup_streams()
