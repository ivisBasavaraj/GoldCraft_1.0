import os, json
os.environ['PYTHONIOENCODING'] = 'utf-8'

from inference_sdk import InferenceHTTPClient, InferenceConfiguration

client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key="JEXqPzJc3orZAABfwro9",
).configure(InferenceConfiguration(api_key_transport="header"))

TEST_IMAGE = r"D:\Pushpa Chains\Digital weight scale detection 2.v1i.yolo26\train\images\WIN_20260601_18_09_47_Pro_jpg.rf.28b89155978dca3593ec30a409f3f57f.jpg"

# Use the public dataset model from rishis-workspace
print("Trying public model: digital-weight-scale-detection-2/1 ...")
result = client.infer(
    inference_input=TEST_IMAGE,
    model_id="digital-weight-scale-detection-2/1",
)
print(json.dumps(result, indent=2, default=str))
