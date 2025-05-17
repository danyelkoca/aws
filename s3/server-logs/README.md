# S3 Server Access Logging and Athena Query Example

This guide demonstrates how to enable server access logging from a source bucket to a destination bucket in Amazon S3.

## Table of Contents

- [Step 1: Create Source and Destination Buckets](#step-1-create-source-and-destination-buckets)
- [Step 2: Enable Logging on Source Bucket](#step-2-enable-logging-on-source-bucket)
- [Step 3: Prepare Destination Bucket](#step-3-prepare-destination-bucket)
- [Step 4: Set Bucket Policy for Logging Access](#step-4-set-bucket-policy-for-logging-access)
- [Step 5: Verify Logging Configuration](#step-5-verify-logging-configuration)
- [Step 6: Generate Activity on Source Bucket](#step-6-generate-activity-on-source-bucket)
- [Step 7: Check Logs in Destination Bucket](#step-7-check-logs-in-destination-bucket)
- [Step 8: Download Logs](#step-8-download-logs)
- [Step 9: Query Logs with Athena](#step-9-query-logs-with-athena)
  - [9.1 Create Athena Database and Table](#91-create-athena-database-and-table)
  - [9.2 Run Queries](#92-run-queries)
  - [9.3 Sync Query Results Locally](#93-sync-query-results-locally)
  - [9.4 Optional: Query Specific Fields](#94-optional-query-specific-fields)
- [Step 10: Cleanup Resources (Avoid Charges)](#step-10-cleanup-resources-avoid-charges)

## Step 1: Create Source and Destination Buckets

Create the source bucket to generate access logs and the destination bucket to store those logs.

```bash
# Create the source S3 bucket
aws s3 mb s3://<SOURCE_BUCKET>

# Create the destination S3 bucket
aws s3 mb s3://<DESTINATION_BUCKET>
```

## Step 2: Enable Logging on Source Bucket

Configure the source bucket to send server access logs to the destination bucket under the specified prefix.

```bash
# Enable server access logging on the source bucket
aws s3api put-bucket-logging \
    --bucket <SOURCE_BUCKET> \
    --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "<DESTINATION_BUCKET>",
            "TargetPrefix": "logs/"
        }
    }'
```

## Step 3: Prepare Destination Bucket

Create a placeholder object in the destination bucket to ensure the `logs/` prefix exists.

```bash
# Create a placeholder object under the logs/ prefix in the destination bucket
aws s3api put-object \
    --bucket <DESTINATION_BUCKET> \
    --key logs/
```

## Step 4: Set Bucket Policy for Logging Access

Allow the S3 logging service to write logs to the destination bucket.

```bash
# Set the bucket policy to permit logging service to write to the destination bucket
aws s3api put-bucket-policy \
  --bucket <DESTINATION_BUCKET> \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "logging.s3.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::<DESTINATION_BUCKET>/logs/*"
      }
    ]
  }'
```

## Step 5: Verify Logging Configuration

Confirm that logging is correctly configured on the source bucket.

```bash
# Retrieve the logging configuration of the source bucket to verify setup
aws s3api get-bucket-logging \
    --bucket <SOURCE_BUCKET>
```

```json
{
  "LoggingEnabled": {
    "TargetBucket": "<DESTINATION_BUCKET>",
    "TargetPrefix": "logs/"
  }
}
```

## Step 6: Generate Activity on Source Bucket

Upload an object to the source bucket to generate server access log entries.

```bash
# Create a test file locally
echo "Hello Mars" > hello.txt

# Upload the test file to the source bucket to generate activity
aws s3 cp hello.txt s3://<SOURCE_BUCKET>/hello1.txt
```

## Step 7: Check Logs in Destination Bucket

List objects under the log prefix in the destination bucket to verify that logs are being delivered.

```bash
# List log files stored in the destination bucket under logs/ prefix
aws s3 ls s3://<DESTINATION_BUCKET>/logs/
```

Output:

```
2025-05-17 13:11:49          0
2025-05-17 13:16:25        677 <LOG_FILE>
2025-05-17 13:16:33        690 <LOG_FILE>
2025-05-17 13:18:41       2714 <LOG_FILE>
2025-05-17 13:18:54        652 <LOG_FILE>
2025-05-17 13:19:26        652 <LOG_FILE>
2025-05-17 13:25:48       2714 <LOG_FILE>
2025-05-17 13:31:18        703 <LOG_FILE>
2025-05-17 13:35:31       2714 <LOG_FILE>
2025-05-17 13:37:49        690 <LOG_FILE>
2025-05-17 13:38:25       2646 <LOG_FILE>
2025-05-17 13:39:09        678 <LOG_FILE>
2025-05-17 13:39:36        652 <LOG_FILE>
2025-05-17 13:41:37       2100 <LOG_FILE>
```

## Step 8: Download Logs

Download the log files from the destination bucket to your local machine for inspection.

```bash
# Sync log files from the destination bucket to local logs/ directory
aws s3 sync s3://<DESTINATION_BUCKET>/logs/ ./logs/
```

---

## Step 9: Query Logs with Athena

This section covers creating an Athena database and table for querying S3 server access logs, running queries, and retrieving results.

### 9.1 Create Athena Database and Table

Create an S3 bucket to store Athena query results and set up the Athena environment.

```bash
# Create S3 bucket to store Athena query results
aws s3 mb s3://<QUERY_RESULT_BUCKET>
```

```bash
# Drop existing Athena table (if exists)
aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS s3_logs.s3_server_logs;" \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

```bash
# Create Athena database if it does not exist
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS s3_logs;" \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

```bash
# Create Athena table using external SQL file defining the schema
aws athena start-query-execution \
  --query-string file://create_s3_log_table.sql \
  --query-execution-context Database=s3_logs \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

### 9.2 Run Queries

Run a simple query to retrieve 10 rows from the server logs table.

```bash
# Execute query to select 10 rows from the server logs table
aws athena start-query-execution \
  --query-string "SELECT * FROM s3_logs.s3_server_logs LIMIT 10;" \
  --query-execution-context Database=s3_logs \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

### 9.3 Sync Query Results Locally

Download the CSV query results from the S3 bucket to your local machine.

```bash
# Sync Athena query result CSV files to local results/ directory
aws s3 sync s3://<QUERY_RESULT_BUCKET>/ ./results/ --exclude "*" --include "*.csv"
```

### 9.4 Optional: Query Specific Fields

Run a query to select specific fields such as user, bucket name, object name, request time, and request type.

```bash
# Query specific fields filtered by source bucket name
aws athena start-query-execution \
  --query-string "SELECT bucket_owner, bucket, requester, operation, key FROM s3_logs.s3_server_logs WHERE bucket = '<SOURCE_BUCKET>' LIMIT 10;" \
  --query-execution-context Database=s3_logs \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

## Step 10: Cleanup Resources (Avoid Charges)

After you're done experimenting, you may want to remove all resources to avoid unnecessary charges.

```bash
# Drop the Athena table
aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS s3_logs.s3_server_logs;" \
  --query-execution-context Database=s3_logs \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

```bash
# Drop the Athena database (optional)
aws athena start-query-execution \
  --query-string "DROP DATABASE IF EXISTS s3_logs;" \
  --result-configuration OutputLocation=s3://<QUERY_RESULT_BUCKET>/
```

```bash
# Delete the Athena query result bucket and its contents
aws s3 rb s3://<QUERY_RESULT_BUCKET> --force
```
