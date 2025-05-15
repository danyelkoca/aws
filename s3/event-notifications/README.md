# Setting Up Event Notifications on S3

This guide provides a step-by-step template to set up event notifications on an S3 bucket using Terraform. Follow along to configure notifications for EventBridge, Lambda, and SNS.

---

## Prerequisites

1. Install Terraform on macOS:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

2. Ensure you have AWS CLI installed and configured with appropriate permissions.

---

## Step 1: Create Terraform Configuration

1. Navigate to the folder where you want to create the Terraform configuration file.
2. Create a `main.tf` file with the following content:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
}

provider "aws" {}

resource "aws_s3_bucket" "default" {}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.default.id
  eventbridge = true
}

output "bucket_name" {
  value = aws_s3_bucket.default.bucket
}
```

---

## Step 2: Deploy the Configuration

1. Initialize Terraform:

```bash
terraform init
```

2. Plan the deployment:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply --auto-approve
```

---

## Step 3: Add an Object to the S3 Bucket

1. Create a sample file:

```bash
echo 'Hello World' > hello.txt
```

2. Upload the file to the S3 bucket:

```bash
aws s3 cp hello.txt s3://<your-bucket-name>
```

Replace `<your-bucket-name>` with the name of your S3 bucket from the Terraform output.

---

## Step 4: Verify EventBridge Notifications

1. Check the EventBridge console for events triggered by the S3 bucket.
2. Example event payload:

```json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "<region>",
      "eventTime": "<timestamp>",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": {
          "name": "<your-bucket-name>",
          "arn": "arn:aws:s3:::<your-bucket-name>"
        },
        "object": {
          "key": "hello.txt",
          "size": 20
        }
      }
    }
  ]
}
```

---

## Step 5: Configure Lambda Notifications

1. Create a Lambda function to process S3 events.
2. Add the Lambda function ARN to the S3 bucket notification configuration.
3. View Lambda logs in CloudWatch:

   - Navigate to the CloudWatch console.
   - Go to Logs > Log Groups.
   - Select the log group for your Lambda function.
   - View the most recent log stream for execution details.

---

## Step 6: Configure SNS Notifications

1. Create an SNS topic in the AWS Management Console.
2. Add the topic ARN to the S3 bucket notification configuration.
3. Subscribe an email address to the SNS topic.
4. Approve the subscription from your email.
5. Upload a file to the S3 bucket and check your email for notifications.

---

This template provides a comprehensive guide to setting up event notifications on S3. Customize the configurations as needed for your use case.
