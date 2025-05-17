# S3 Server Access Logging Example

This guide demonstrates how to enable server access logging from a source bucket to a destination bucket in Amazon S3.

## Step 1: Create Source and Destination Buckets

Create two S3 buckets: one to generate access logs (source) and one to receive them (destination).

```bash
aws s3 mb s3://<SOURCE_BUCKET>
aws s3 mb s3://<DESTINATION_BUCKET>
```

## Step 2: Enable Logging on Source Bucket

Configure the source bucket to send access logs to the destination bucket under the specified prefix.

```bash
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

Create a placeholder object to ensure the `logs/` prefix exists in the destination bucket.

```bash
aws s3api put-object \
    --bucket <DESTINATION_BUCKET> \
    --key logs/
```

## Step 4: Set Bucket Policy for Logging Access

Allow the S3 logging service to write logs to the destination bucket.

```bash
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
        "Resource": "arn:aws:s3::<DESTINATION_BUCKET>/logs/*"
      }
    ]
  }'
```

## Step 5: Verify Logging Configuration

Confirm that logging is correctly configured on the source bucket.

```bash
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

Upload an object to the source bucket to trigger a log entry.

```bash
echo "Hello Mars" > hello.txt
aws s3 cp hello.txt s3://<SOURCE_BUCKET>/hello1.txt
```

## Step 7: Check Logs in Destination Bucket

List objects under the log prefix in the destination bucket to verify logs are being delivered.

```bash
aws s3 ls s3://<DESTINATION_BUCKET>/logs/
```

Output:

```
2025-05-17 13:11:49          0
2025-05-17 13:16:25        677 <LOG_FILE_1>
2025-05-17 13:16:33        690 <LOG_FILE_2>
2025-05-17 13:18:41       2714 <LOG_FILE_3>
2025-05-17 13:18:54        652 <LOG_FILE_4>
2025-05-17 13:19:26        652 <LOG_FILE_5>
2025-05-17 13:25:48       2714 <LOG_FILE_6>
2025-05-17 13:31:18        703 <LOG_FILE_7>
2025-05-17 13:35:31       2714 <LOG_FILE_8>
2025-05-17 13:37:49        690 <LOG_FILE_9>
2025-05-17 13:38:25       2646 <LOG_FILE_10>
2025-05-17 13:39:09        678 <LOG_FILE_11>
2025-05-17 13:39:36        652 <LOG_FILE_12>
2025-05-17 13:41:37       2100 <LOG_FILE_13>
```
