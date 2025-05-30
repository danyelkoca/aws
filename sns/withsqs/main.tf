provider "aws" {
  region = "ap-northeast-1"
}

###################
# SNS Topic Setup #
###################
resource "aws_sns_topic" "notifications" {
  name = "message-processor-topic"
}

##################
# SQS Queue Setup #
##################
resource "aws_sqs_queue" "notification_queue" {
  name                       = "message-processor-queue"
  visibility_timeout_seconds = 30    # Should match Lambda timeout
  message_retention_seconds  = 86400 # 1 day
}

# Allow SNS to send messages to SQS
resource "aws_sqs_queue_policy" "notification_queue_policy" {
  queue_url = aws_sqs_queue.notification_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notification_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sns_topic.notifications.arn
          }
        }
      }
    ]
  })
}

# Connect SQS queue to SNS topic
resource "aws_sns_topic_subscription" "queue" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_queue.arn
}

# Create DynamoDB table for message history
resource "aws_dynamodb_table" "message_history" {
  name         = "message-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "MessageId"

  attribute {
    name = "MessageId"
    type = "S"
  }
}

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "message_processor_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Allow Lambda to write CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to read from SQS
resource "aws_iam_role_policy" "lambda_sqs" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = [aws_sqs_queue.notification_queue.arn]
    }]
  })
}

# Allow Lambda to write to DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem"
      ]
      Resource = [aws_dynamodb_table.message_history.arn]
    }]
  })
}

# Create Lambda function
resource "aws_lambda_function" "message_processor" {
  filename      = "lambda_function.zip"
  function_name = "message-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.message_history.name
    }
  }
}

# Create Lambda permission to allow SQS to invoke it
resource "aws_lambda_permission" "sqs_permission" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.message_processor.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.notification_queue.arn
}

# Create event source mapping between SQS and Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda" {
  event_source_arn = aws_sqs_queue.notification_queue.arn
  function_name    = aws_lambda_function.message_processor.arn
  batch_size       = 1
}

# Output commands for testing
output "publish_message" { value = "aws sns publish --topic-arn ${aws_sns_topic.notifications.arn} --message 'Hello from SNS!' --region ap-northeast-1" }
output "read_from_sqs" { value = "aws sqs receive-message --queue-url ${aws_sqs_queue.notification_queue.url} --region ap-northeast-1" }
output "view_saved_messages" { value = "aws dynamodb scan --table-name ${aws_dynamodb_table.message_history.name} --region ap-northeast-1" }
