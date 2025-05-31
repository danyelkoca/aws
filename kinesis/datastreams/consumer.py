import boto3
import json
import time
from datetime import datetime
from collections import defaultdict

# Initialize Kinesis client
kinesis = boto3.client("kinesis", region_name="ap-northeast-1")
STREAM_NAME = "web-log-stream"

# In-memory storage for basic analytics
ip_request_count = defaultdict(int)
path_status_counts = defaultdict(lambda: defaultdict(int))
recent_errors = []


def process_record(record_data):
    """Process a single log record"""
    try:
        log_entry = json.loads(record_data)

        # Update IP request count
        ip_request_count[log_entry["ip_address"]] += 1

        # Update path status counts
        path_status_counts[log_entry["path"]][log_entry["status_code"]] += 1

        # Track errors (status code >= 400)
        if log_entry["status_code"] >= 400:
            recent_errors.append(log_entry)
            if len(recent_errors) > 10:  # Keep only last 10 errors
                recent_errors.pop(0)

        # Print the processed record
        print(f"\n📝 Processed Log Entry:")
        print(f"Time: {log_entry['timestamp']}")
        print(f"IP: {log_entry['ip_address']}")
        print(
            f"{log_entry['http_method']} {log_entry['path']} - {log_entry['status_code']}"
        )
        print(f"Response Time: {log_entry['response_time']}s")

        # Print analytics every 10 records
        if sum(ip_request_count.values()) % 10 == 0:
            print_analytics()

    except Exception as e:
        print(f"❌ Error processing record: {str(e)}")


def print_analytics():
    """Print current analytics"""
    print("\n📊 Current Analytics:")

    # Top 3 IPs by request count
    print("\nTop 3 Active IPs:")
    for ip, count in sorted(ip_request_count.items(), key=lambda x: x[1], reverse=True)[
        :3
    ]:
        print(f"{ip}: {count} requests")

    # Path status code distribution
    print("\nPath Status Code Distribution:")
    for path, status_counts in path_status_counts.items():
        print(f"\n{path}:")
        for status, count in status_counts.items():
            print(f"  {status}: {count}")

    # Recent errors
    if recent_errors:
        print("\n⚠️ Recent Errors:")
        for error in recent_errors[-5:]:  # Show last 5 errors
            print(
                f"{error['timestamp']} - {error['http_method']} {error['path']} - {error['status_code']}"
            )


def main():
    """Main function to continuously read from Kinesis stream"""
    print(f"🎯 Starting consumer for stream: {STREAM_NAME}")

    # Get shard iterator
    response = kinesis.describe_stream(StreamName=STREAM_NAME)
    shard_id = response["StreamDescription"]["Shards"][0]["ShardId"]

    shard_iterator = kinesis.get_shard_iterator(
        StreamName=STREAM_NAME, ShardId=shard_id, ShardIteratorType="LATEST"
    )["ShardIterator"]

    while True:
        # Get records from stream
        response = kinesis.get_records(ShardIterator=shard_iterator, Limit=10)

        # Process any records received
        for record in response["Records"]:
            process_record(record["Data"])

        # Update shard iterator
        shard_iterator = response["NextShardIterator"]

        # Wait before next poll if no records received
        if not response["Records"]:
            time.sleep(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⏹️  Stopping consumer")
