import os, json
os.environ['PYTHONIOENCODING'] = 'utf-8'

from inference_sdk import InferenceHTTPClient, InferenceConfiguration
import requests

API_KEY = "JEXqPzJc3orZAABfwro9"

# List projects in workspace via Roboflow REST API
resp = requests.get(
    "https://api.roboflow.com/aryan-k",
    params={"api_key": API_KEY},
)
print("=== WORKSPACE PROJECTS ===")
print(json.dumps(resp.json(), indent=2, default=str))
