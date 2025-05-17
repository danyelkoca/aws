# LocalStack S3 Testing Guide

## Installation

Install the LocalStack CLI using Homebrew:

```bash
brew install localstack/tap/localstack-cli
```

## Starting LocalStack

Start the LocalStack service:

```bash
localstack start
```

Note: You need to run Docker Desktop for Mac to use LocalStack CLI.

## Check Status

Check the status of the LocalStack instance:

```bash
localstack status
```

Example output:

```
┌─────────────────┬───────────────────────────────────────────────────────┐
│ Runtime version │ 4.4.1.dev21                                           │
│ Docker image    │ tag: latest, id: b1b9f264d6c6, 📆 2025-05-16T16:31:16 │
│ Runtime status  │ ✔ running (name: "localstack-main", IP: 172.17.0.2)   │
└─────────────────┴───────────────────────────────────────────────────────┘
```

## S3 Bucket Operations

### Create Bucket

Create a mock S3 bucket using the AWS CLI:

```bash
aws s3 mb s3://bucket --endpoint-url=http://localhost:4566
```

### List Buckets

List all S3 buckets in LocalStack:

```bash
aws s3 ls --endpoint-url=http://localhost:4566
```

## Environment Configuration

Set environment variable for the custom endpoint URL:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
```

Don't forget to remove the environment variable after you are done testing:

```bash
unset AWS_ENDPOINT_URL
```

## Logs and Activity

When you perform operations on LocalStack, you can view logs similar to the following:

```
2025-05-17T08:48:12.787  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.ListBuckets => 200
2025-05-17T08:48:34.946  INFO --- [et.reactor-0] localstack.request.http    : GET / => 200
2025-05-17T08:48:35.053  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.ListObjects => 404 (NoSuchBucket)
2025-05-17T08:48:40.147  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.GetObject => 404 (NoSuchBucket)
2025-05-17T08:49:09.528  INFO --- [et.reactor-0] localstack.request.http    : GET / => 200
2025-05-17T08:49:09.629  INFO --- [et.reactor-0] l.aws.handlers.cors        : Blocked CORS request from forbidden origin http://127.0.0.1:4566/
2025-05-17T08:49:14.874  INFO --- [et.reactor-0] localstack.request.http    : GET / => 200
2025-05-17T08:51:18.824  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.CreateBucket => 200
2025-05-17T08:51:32.210  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.ListBuckets => 200
2025-05-17T08:52:53.655  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.CreateBucket => 200
2025-05-17T08:53:12.293  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.ListBuckets => 200
2025-05-17T08:57:43.116  INFO --- [et.reactor-0] localstack.request.aws     : AWS s3.ListBuckets => 200
```

## Python Example with Boto3

Example Python script to list S3 buckets using boto3 and the LocalStack endpoint:

```python
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

```
