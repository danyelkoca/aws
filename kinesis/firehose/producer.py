import boto3
import json
import random
import time
from datetime import datetime
from faker import Faker

# Initialize Faker for generating realistic-looking data
fake = Faker()

# Initialize Firehose client
import os

region = os.environ.get("AWS_REGION", "ap-northeast-1")
firehose = boto3.client("firehose", region_name=region)
STREAM_NAME = "web-analytics-stream"


def generate_log_entry():
    """Generate a fake web server log entry"""

    # List of possible HTTP methods and status codes
    http_methods = ["GET", "POST", "PUT", "DELETE"]
    status_codes = [200, 200, 200, 201, 400, 401, 403, 404, 500]  # weighted towards 200
    paths = [
        "/home",
        "/login",
        "/logout",
        "/api/users",
        "/api/products",
        "/search",
        "/categories",
        "/cart",
        "/checkout",
        "/profile",
    ]

    timestamp = datetime.now().isoformat()
    entry = {
        "timestamp": timestamp,
        "ip_address": fake.ipv4(),
        "user_agent": fake.user_agent(),
        "http_method": random.choice(http_methods),
        "path": random.choice(paths),
        "status_code": random.choice(status_codes),
        "response_time": round(random.uniform(0.1, 2.0), 3),
    }

    return entry


def send_to_firehose(entry):
    """Send log entry to Kinesis Firehose"""
    try:
        response = firehose.put_record(
            DeliveryStreamName=STREAM_NAME, Record={"Data": json.dumps(entry) + "\n"}
        )
        print(f"✅ Sent log entry to Firehose - RecordId: {response['RecordId']}")
        return True
    except Exception as e:
        print(f"❌ Error sending to Firehose: {str(e)}")
        return False


def main():
    """Main loop to generate and send log entries"""
    print(f"🚀 Starting log producer, sending to Firehose stream: {STREAM_NAME}")
    records_sent = 0

    while True:
        try:
            log_entry = generate_log_entry()
            if send_to_firehose(log_entry):
                records_sent += 1

            # Print statistics every 100 records
            if records_sent % 100 == 0:
                print(f"\n📊 Statistics:")
                print(f"Total records sent: {records_sent}")

            # Wait between 0.1-0.5 seconds before next log
            time.sleep(random.uniform(0.1, 0.5))

        except KeyboardInterrupt:
            print(f"\n⏹️  Stopping producer. Total records sent: {records_sent}")
            break


if __name__ == "__main__":
    main()
