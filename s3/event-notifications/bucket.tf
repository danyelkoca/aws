resource "aws_s3_bucket" "default" {}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.default.id

  eventbridge = true

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "queue/"
  }

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "topic/"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "lambda/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

output "bucket_name" {
  value = aws_s3_bucket.default.bucket
}
