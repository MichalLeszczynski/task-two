import boto3
import json
import datetime
import os

dynamodb = boto3.resource("dynamodb")

def request_handler(event, context):
    print(f"Received event: {event}")
    request_result = "Empty"
    try:
        body = json.loads(event.get("body"))
        action = body.get("action")
        print(f"Action: {action}")
        stack_name = body.get("stack_name", "task-two-stack")
        launch_params = body.get("launch_params")
        timestamp = datetime.datetime.now().isoformat()

        db_entry = {
            "Stackname": stack_name,
            "Timestamp": timestamp,
            "Action": action,
            "LaunchParams": launch_params,
        }

        table = dynamodb.Table(os.environ["ActionsDynamoDbTableName"])
        request_result = table.put_item(Item=db_entry)
    except Exception as err:
        print(str(err))
    finally:
        print(request_result)
        return request_result
