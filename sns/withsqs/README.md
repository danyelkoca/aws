# Message Processing Pipeline with AWS Services

This project demonstrates a serverless message processing pipeline using AWS services.

## Architecture

```
[SNS Topic] → [SQS Queue] → [Lambda Function] → [DynamoDB Table]
```

## Components

1. **SNS (Simple Notification Service)**

   - Entry point for messages
   - Decouples message publishing from processing
   - Enables future addition of other subscribers

2. **SQS (Simple Queue Service)**

   - Buffers messages for processing
   - Handles traffic spikes
   - 30-second visibility timeout
   - 1-day message retention

3. **Lambda Function**

   - Processes messages from SQS
   - Handles one message at a time
   - Stores message data in DynamoDB
   - Automatically retries on failures

4. **DynamoDB**
   - Stores message history
   - Schema:
     - MessageId (primary key)
     - Message content
     - Timestamp
     - Source information

## Setup

1. Package the Lambda function:

```bash
chmod +x package.sh
./package.sh
```

2. Deploy the infrastructure:

```bash
terraform init
terraform apply
```

## Testing

1. Send a test message:

```bash
# Get and run the publish command
terraform output publish_message
```

2. (Optional) Check message in SQS:

```bash
# Get and run the SQS read command
terraform output read_from_sqs
```

3. View processed messages in DynamoDB:

```bash
# Get and run the DynamoDB scan command
terraform output view_saved_messages
```

Note: The Lambda function uses boto3 which is pre-installed in the AWS Lambda Python runtime environment, so we don't need to include it in our deployment package.

## Message Flow

1. Message published to SNS topic
2. SNS sends message to SQS queue
3. Lambda function is triggered by new messages in SQS
4. Lambda processes message and saves to DynamoDB
5. Message is deleted from SQS upon successful processing

## Error Handling

- Failed Lambda invocations are retried automatically
- Messages that fail processing remain in SQS
- Messages not processed within visibility timeout return to queue
- Messages not processed within retention period (1 day) are deleted

## Cleanup

Remove all resources:

```bash
terraform destroy
```
