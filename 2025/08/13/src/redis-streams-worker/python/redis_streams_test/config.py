import json
import os
import pathlib

def get_redis_config():
    home = str(pathlib.Path.home())
    secrets_file = os.path.join(home, ".secrets", "secrets.json")
    
    with open(secrets_file) as f:
        secrets = json.load(f)
    
    redis = secrets["redis"]
    return redis["host"], redis["port"], redis["password"]
