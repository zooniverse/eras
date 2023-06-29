import json
import base64
import requests

HEADERS  = {"Content-Type": "application/json", "Accept": "application/json"}
ENDPOINT = "https://eras-staging.zooniverse.org/kinesis"

def lambda_handler(event, context):
    payloads = [json.loads(base64.b64decode(record["kinesis"]["data"])) for record in event["Records"]]
    dicts    = [payload for payload in payloads]

    if dicts:
        data = json.dumps({"payload": dicts})
        r = requests.post(ENDPOINT, headers=HEADERS, data=data)
        r.raise_for_status()
