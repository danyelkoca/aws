provider "aws" {
  region = "ap-northeast-1"
}

# Create S3 bucket for storing raw images
resource "aws_s3_bucket" "raw_image_bucket" {
  bucket_prefix = "raw-images-"
  force_destroy = true
}

# Create S3 bucket for storing thumbnails
resource "aws_s3_bucket" "thumbnail_bucket" {
  bucket_prefix = "thumbnails-"
  force_destroy = true
}

# Upload the sample image to raw images bucket
resource "aws_s3_object" "sample_image" {
  bucket = aws_s3_bucket.raw_image_bucket.id
  key    = "image.png"
  source = "${path.module}/image.png"
  etag   = filemd5("${path.module}/image.png")
}

resource "aws_sqs_queue" "job_queue" {
  name                       = "image-thumbnail-job-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-exec-role"

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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.raw_image_bucket.arn}/*" # Read from raw images bucket
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.thumbnail_bucket.arn}/*" # Write to thumbnails bucket
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "image_resizer" {
  function_name = "image-thumbnail-worker"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  filename         = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  timeout          = 30  # Increase timeout to 30 seconds
  memory_size      = 256 # Increase memory to 256 MB

  environment {
    variables = {
      SQS_QUEUE_URL    = aws_sqs_queue.job_queue.id
      RAW_BUCKET_NAME  = aws_s3_bucket.raw_image_bucket.id
      THUMBNAIL_BUCKET = aws_s3_bucket.thumbnail_bucket.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.job_queue.arn
  function_name    = aws_lambda_function.image_resizer.arn
  batch_size       = 5
  enabled          = true
}

output "raw_bucket_name" {
  value = aws_s3_bucket.raw_image_bucket.id
}

output "thumbnail_bucket_name" {
  value = aws_s3_bucket.thumbnail_bucket.id
}

output "example_image_command" {
  value = <<-EOT
aws sqs send-message \
  --queue-url ${aws_sqs_queue.job_queue.id} \
  --message-body '{"bucket": "${aws_s3_bucket.raw_image_bucket.id}", "key": "image.png"}' \
  --region ap-northeast-1
EOT
}
