import subprocess

def envy_secret_get(*path):
    """Execute 'envy secret get' command with the given path components."""
    cmd = ["envy", "secret", "get"] + list(path)
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        value = result.stdout.strip()
        
        # if not value:
        #     raise ValueError(f"Empty value returned for {'.'.join(path)}")
        
        return value
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"envy command failed for {'.'.join(path)}: {e.stderr.strip()}")
    except FileNotFoundError:
        raise RuntimeError("envy command not found. Make sure it's installed and in your PATH.")

def get_redis_config():
    """Get Redis configuration using envy command line tool."""
    host = envy_secret_get("redis", "host")
    port = int(envy_secret_get("redis", "port"))
    password = envy_secret_get("redis", "password")
    
    return host, port, password
