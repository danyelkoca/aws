data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.default.arn
}

resource "aws_lambda_function" "func" {
  filename      = "functions/handler.py.zip" # Path to your zipped Lambda function code
  function_name = "example_lambda_name"      # Name of your Lambda function
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "handler.lambda_handler" # Assuming your function is named lambda_handler
  runtime       = "python3.13"             # Latest stable Python runtime as of 2024
}

## To write logs to CloudWatch, attach the AWSLambdaBasicExecutionRole policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


