import json
import os
import boto3
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])


def handler(event, context):
    """Process messages from SQS and store in DynamoDB."""
    print(f"Processing {len(event['Records'])} messages")

    for record in event["Records"]:
        # Extract message from SQS (which contains the SNS message)
        body = json.loads(record["body"])
        message = body["Message"]

        # Store in DynamoDB
        item = {
            "MessageId": record["messageId"],  # Using SQS message ID
            "Message": message,
            "Timestamp": datetime.utcnow().isoformat(),
        }

        table.put_item(Item=item)
        print(f"Stored message: {message}")
