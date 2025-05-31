# Configure AWS Provider - Using Tokyo region as specified in other configs
provider "aws" {
  region = "ap-northeast-1"
}

######################
# Kinesis Data Stream
######################

resource "aws_kinesis_stream" "log_stream" {
  name             = "web-log-stream"
  shard_count      = 1  # Minimum shards to keep costs low
  retention_period = 24 # Minimum retention in hours (24-168 hours)

  # Stream mode - choose PROVISIONED for predictable costs
  # ON_DEMAND would auto-scale but could be more expensive
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  # Enable server-side encryption with AWS managed key (no additional cost)
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis" # AWS managed key for Kinesis

  # Tags for resource management
  tags = {
    Environment = "demo"
    Purpose     = "log-analysis"
  }
}

######################
# IAM Roles & Policies
######################

# IAM policy for local testing
# Note: These permissions should be attached to your AWS user/role
# Required permissions for local testing:
# - kinesis:PutRecord, kinesis:PutRecords (for producer)
# - kinesis:GetShardIterator, kinesis:GetRecords, kinesis:DescribeStream, kinesis:ListShards (for consumer)

# For production environments, you might want to create specific IAM roles
# for EC2 instances or other AWS services that need to interact with Kinesis

######################
# Outputs
######################

output "kinesis_stream_name" {
  description = "The name of the Kinesis stream"
  value       = aws_kinesis_stream.log_stream.name
}

output "kinesis_stream_arn" {
  description = "The ARN of the Kinesis stream"
  value       = aws_kinesis_stream.log_stream.arn
}

# Only stream information is needed for local testing
