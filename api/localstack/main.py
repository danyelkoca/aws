import os
import boto3


def list_s3_buckets():
    # Get the custom endpoint URL from the environment variable
    endpoint_url = os.getenv("AWS_ENDPOINT_URL", "http://localhost:4566")

    # Create a boto3 client with the custom endpoint
    s3_client = boto3.client("s3", endpoint_url=endpoint_url)

    # Example usage: List buckets
    response = s3_client.list_buckets()
    print("Buckets:", response.get("Buckets", []))


if __name__ == "__main__":
    list_s3_buckets()


## Returns
# Buckets: [
#     {
#         "Name": "bucket",
#         "CreationDate": datetime.datetime(2025, 5, 17, 8, 52, 53, tzinfo=tzutc()),
#     },
#     {
#         "Name": "my-bucket",
#         "CreationDate": datetime.datetime(2025, 5, 17, 8, 51, 18, tzinfo=tzutc()),
#     },
# ]
