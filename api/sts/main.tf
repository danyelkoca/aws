terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1" # Specify the AWS provider version
    }
  }
}

# Terraform and AWS Provider
provider "aws" {} # Configure the AWS provider

# S3 Bucket
# Create an S3 bucket named "<BUCKET_NAME>"
resource "aws_s3_bucket" "dannykbucket" {
  bucket = "<BUCKET_NAME>" # Name of the S3 bucket
}

# S3 Bucket Object
# Add a hello.txt object to the S3 bucket
resource "aws_s3_object" "hello_txt" {
  bucket  = aws_s3_bucket.dannykbucket.bucket # Reference the S3 bucket
  key     = "hello.txt"                       # Name of the object
  content = "Hello, world!"                   # Content of the object
}

# IAM Policy: Read-only Access to S3
# Define the policy document granting read-only access to the S3 bucket
data "aws_iam_policy_document" "readonly_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]                                       # Actions allowed by the policy
    resources = [aws_s3_bucket.dannykbucket.arn, "${aws_s3_bucket.dannykbucket.arn}/*"] # Resources the policy applies to
  }
}

# Create an IAM policy from the above document
resource "aws_iam_policy" "readonly_policy" {
  name        = "readonly-policy"                                   # Name of the policy
  description = "Policy granting read-only access to the S3 bucket" # Description of the policy
  policy      = data.aws_iam_policy_document.readonly_policy.json   # Policy document
}

# IAM User (No Direct Permissions)
# Create an IAM user without any direct permissions
resource "aws_iam_user" "no_permissions_user" {
  name = "<IAM_USER_NAME>" # Name of the IAM user
}

# IAM Role to Be Assumed
# Define the assume role policy document that allows the IAM user to assume this role
data "aws_iam_policy_document" "sts_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"] # Allow the action to assume the role

    principals {
      type        = "AWS"                                  # Principal type is AWS
      identifiers = [aws_iam_user.no_permissions_user.arn] # The IAM user allowed to assume the role
    }
  }
}

# Create the IAM role which can be assumed by the IAM user
resource "aws_iam_role" "sts_role" {
  name               = "<IAM_ROLE_NAME>"                                        # Name of the IAM role
  assume_role_policy = data.aws_iam_policy_document.sts_assume_role_policy.json # Policy allowing the user to assume this role
}

# Attach the read-only S3 access policy to the IAM role
resource "aws_iam_role_policy_attachment" "readonly_policy_attachment" {
  role       = aws_iam_role.sts_role.name         # IAM role to attach the policy to
  policy_arn = aws_iam_policy.readonly_policy.arn # ARN of the policy to attach
}

# IAM Policy: Allow User to Assume Role
# Create a policy that allows the IAM user to assume the sts_role
resource "aws_iam_policy" "assume_sts_role_policy" {
  name        = "assume-sts-role-policy"
  description = "Policy that allows assuming sts_role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = aws_iam_role.sts_role.arn
      }
    ]
  })
}

# Attach the above assume-role policy to the IAM user
resource "aws_iam_user_policy_attachment" "assume_sts_role_attachment" {
  user       = aws_iam_user.no_permissions_user.name
  policy_arn = aws_iam_policy.assume_sts_role_policy.arn
}

# IAM User Access Key
# Create an access key for the IAM user to enable programmatic access
resource "aws_iam_access_key" "no_permissions_user_key" {
  user = aws_iam_user.no_permissions_user.name
}

# Outputs
# Output the IAM user's access key ID and secret access key as sensitive values
output "no_permissions_user_access_key" {
  value     = aws_iam_access_key.no_permissions_user_key.id
  sensitive = true
}

output "no_permissions_user_secret_key" {
  value     = aws_iam_access_key.no_permissions_user_key.secret
  sensitive = true
}

# Usage Instructions

# Step 1: Retrieve credentials
# These commands will output your IAM user's access key and secret
# Run in terminal:
# terraform output -raw no_permissions_user_access_key
# terraform output -raw no_permissions_user_secret_key

# Step 2: Configure a new AWS CLI profile for the IAM user
# aws configure --profile no-permissions-user
# Provide the values from Step 1 when prompted

# Step 3: Attempting to access the S3 bucket directly will fail (as expected)
# aws s3 ls s3://<BUCKET_NAME> --profile no-permissions-user

# Step 4: Assume the role to gain temporary credentials
# aws sts assume-role \
#   --role-arn arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME> \
#   --role-session-name test-session \
#   --profile no-permissions-user

# You will receive output like:
# {
#   "Credentials": {
#     "AccessKeyId": "<ACCESS_KEY>",
#     "SecretAccessKey": "<SECRET_KEY>",
#     "SessionToken": "<SESSION_TOKEN>",
#     ...
#   },
#   "AssumedRoleUser": {
#     "Arn": "arn:aws:sts::<ACCOUNT_ID>:assumed-role/<IAM_ROLE_NAME>/test-session"
#   }
# }

# Step 5: Create a new CLI profile with the temporary credentials
# aws configure --profile assumed-role-user
# Use the AccessKeyId and SecretAccessKey from Step 4

# Step 6: Add the session token to the temporary profile
# aws configure set aws_session_token "<SESSION_TOKEN>" --profile assumed-role-user

# Step 7: Access the S3 bucket using the assumed role profile
# aws s3 ls s3://<BUCKET_NAME> --profile assumed-role-user
