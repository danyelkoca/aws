# ─────────────────────────────────────────────────────────────
# OPTIONAL: SNS Setup (Email Notification when Lambda executes)
# This section is not required for the cron job to function.
# Remove if notifications are not needed.
# ─────────────────────────────────────────────────────────────

# Create an SNS topic for notifications
resource "aws_sns_topic" "lambda_notification" {
  name = "lambda-notification-topic"
}

# Subscribe an email address to the SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.lambda_notification.arn
  protocol  = "email"  # Notification method
  endpoint  = var.notification_email  # Your email address (must confirm)
}

# IAM Policy allowing Lambda to publish to SNS
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "sns_publish_policy"
  description = "Allow Lambda to publish to SNS topic"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sns:Publish",
      Resource = aws_sns_topic.lambda_notification.arn
    }]
  })
}

# Attach SNS publish policy to the Lambda execution role
resource "aws_iam_policy_attachment" "lambda_sns_attach" {
  name       = "lambda-sns-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

# ─────────────────────────────────────────────────────────────
# CORE INFRASTRUCTURE BELOW (Do not remove for core logic)
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# AWS Provider
# ─────────────────────────────────────────────────────────────

# Configure AWS provider for Tokyo region
provider "aws" {
  region = "ap-northeast-1" # Tokyo
}

# ─────────────────────────────────────────────────────────────
# IAM Role for Lambda Execution
# ─────────────────────────────────────────────────────────────

# Define execution role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic Lambda execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─────────────────────────────────────────────────────────────
# Lambda Function Definition
# ─────────────────────────────────────────────────────────────

# Define the Lambda function that performs the GitHub commit
resource "aws_lambda_function" "daily_git_commit" {
  function_name = "daily_git_commit"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"  # Python handler
  runtime       = "python3.9"
  filename      = "${path.module}/lambda_function_payload.zip"  # Code package path
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")

  # Environment variables for the function to use
  environment {
    variables = {
      GITHUB_TOKEN  = var.github_token      # GitHub token with push access
      REPO_URL      = var.repo_url          # Target repository URL
      COMMIT_EMAIL  = var.commit_email      # Git user.email
      COMMIT_NAME   = var.commit_name       # Git user.name
      SNS_TOPIC_ARN = aws_sns_topic.lambda_notification.arn  # Topic to publish notification
    }
  }
}

# ─────────────────────────────────────────────────────────────
# EventBridge Rule to Trigger Lambda Daily
# ─────────────────────────────────────────────────────────────

# Define daily schedule: 9 AM JST = 0 AM UTC
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "daily-9am-jst"
  schedule_expression = "cron(0 0 * * ? *)" # AWS cron format
}

# Bind EventBridge rule to Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "dailyGitCommit"
  arn       = aws_lambda_function.daily_git_commit.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_git_commit.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}

# ─────────────────────────────────────────────────────────────
# Variables
# ─────────────────────────────────────────────────────────────

# GitHub Personal Access Token
variable "github_token" {
  type = string
}

# GitHub repository URL
variable "repo_url" {
  type = string
}

# Git commit email
variable "commit_email" {
  type = string
}

# Git commit author name
variable "commit_name" {
  type = string
}

# Email address to notify
variable "notification_email" {
  type = string
}