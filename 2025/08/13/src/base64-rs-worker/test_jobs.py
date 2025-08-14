#!/t/venv/rq/bin/python

import json
import base64
from redis_streams_test.client import TestClient
from redis_streams_test.exceptions import JobError

# Initialize client with namespace
client = TestClient("base64")

def run_test(name, command, args):
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

def test_blob_with_mime_type():
    """Test blob command with explicit mime type"""
    test_data = b"Hello, World!"
    args = {
        "blob": base64.b64encode(test_data).decode('utf-8'),
        "mime_type": "text/plain"
    }
    return run_test("blob command with mime type", "blob", args)

def test_filename_with_url():
    """Test filename command with file:// URL"""
    args = {
        "filename": "file:///home/c/Dropbox/2/src/rust/openrouter-rq-worker/Ejemplo_Zona_de_Pruebas_1.png"
    }
    return run_test("filename command with file:// URL", "filename", args)

def test_filename_with_auto_mime():
    """Test filename command with auto-detected mime type"""
    args = {
        "filename": "/home/c/Dropbox/2/src/rust/openrouter-rq-worker/Ejemplo_Zona_de_Pruebas_1.png"
    }
    return run_test("filename command with auto-detected mime type", "filename", args)

def test_filename_with_explicit_mime():
    """Test filename command with explicit mime type"""
    args = {
        "filename": "/home/c/Dropbox/2/src/rust/openrouter-rq-worker/Ejemplo_Zona_de_Pruebas_1.png",
        "mime_type": "application/octet-stream"
    }
    return run_test("filename command with explicit mime type", "filename", args)

def test_error_handling():
    """Test various error cases"""
    print("\nTesting error handling:")

    print("\nMissing required argument:")
    args = {
        "mime_type": "text/plain"  # Missing blob data
    }
    run_test("missing required argument", "blob", args)

    print("\nInvalid base64 data:")
    args = {
        "blob": "not-valid-base64",
        "mime_type": "text/plain"
    }
    run_test("invalid base64 data", "blob", args)

    print("\nFile not found:")
    args = {
        "filename": "/path/to/nonexistent/file.txt"
    }
    run_test("file not found", "filename", args)

if __name__ == '__main__':
    # Clean up any old messages
    print("Cleaning up streams before testing...")
    client.cleanup_streams()
    
    # Run tests
    test_blob_with_mime_type()
    test_filename_with_url()
    test_filename_with_auto_mime()
    test_filename_with_explicit_mime()
    test_error_handling()
    
    # Clean up after testing
    print("\nCleaning up streams after testing...")
    client.cleanup_streams()
