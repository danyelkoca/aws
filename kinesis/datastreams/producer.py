import boto3
import json
import random
import time
from datetime import datetime
from faker import Faker

# Initialize Faker for generating realistic-looking data
fake = Faker()

# Initialize Kinesis client
kinesis = boto3.client("kinesis", region_name="ap-northeast-1")
STREAM_NAME = "web-log-stream"


def generate_log_entry():
    """Generate a fake web server log entry"""

    # List of possible HTTP methods and status codes
    http_methods = ["GET", "POST", "PUT", "DELETE"]
    status_codes = [200, 200, 200, 201, 400, 401, 403, 404, 500]  # weighted towards 200
    paths = ["/home", "/login", "/logout", "/api/users", "/api/products", "/search"]

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


def send_to_kinesis(entry):
    """Send log entry to Kinesis Data Stream"""
    try:
        response = kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(entry),
            PartitionKey=str(entry["ip_address"]),
        )
        print(
            f"✅ Sent log entry to Kinesis - Sequence number: {response['SequenceNumber']}"
        )
        return True
    except Exception as e:
        print(f"❌ Error sending to Kinesis: {str(e)}")
        return False


def main():
    """Main loop to generate and send log entries"""
    print(f"🚀 Starting log producer, sending to stream: {STREAM_NAME}")

    while True:
        log_entry = generate_log_entry()
        send_to_kinesis(log_entry)
        # Wait between 1-3 seconds before next log
        time.sleep(random.uniform(1, 3))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⏹️  Stopping log producer")
