# SQS with Lambda Image Processing Demo

This project demonstrates how to use AWS SQS (Simple Queue Service) with AWS Lambda for asynchronous image processing. The system processes images by creating thumbnails when messages are received through an SQS queue.

## Architecture

```
[SQS Queue] -> [Lambda Function] -> [S3 Bucket]
```

- **SQS Queue**: Receives messages containing image URLs to be processed
- **Lambda Function**: Triggered by SQS messages, downloads images, resizes them, and uploads to S3
- **IAM Role**: Provides necessary permissions for Lambda to access SQS and S3

## Setup Instructions

1. Make sure you have the following prerequisites:

   - AWS CLI configured
   - Terraform installed
   - Python 3.9
   - pip (Python package manager)
   - Required Python packages: Pillow, numpy

2. Generate a random test image:

```bash
cd /Users/danyelkoca/Desktop/projects/aws/sqs/basic && python3 generate_random_image.py
# This will create image.png in the current directory
```

3. Package the Lambda function:

```bash
cd /Users/danyelkoca/Desktop/projects/aws/sqs/basic && chmod +x package.sh && ./package.sh
```

4. Deploy the infrastructure:

```bash
terraform init
terraform apply
```

5. Test the setup by sending a message to the queue:

```bash
# The exact command will be shown in the Terraform output
aws sqs send-message --queue-url <QUEUE_URL> --message-body '{"bucket": "your-bucket-name", "key": "image.png", "width": 100, "height": 100}'
```

## Lambda Function

The Lambda function:

- Receives messages from SQS containing image URLs
- Downloads the images
- Resizes them to create thumbnails
- Uploads the processed images to S3

### Packaging with Docker

The Lambda function is packaged using Docker for several important reasons:

1. **Platform Compatibility**: Lambda runs on Amazon Linux (Linux-based), while development might happen on different operating systems (like macOS). Using Docker ensures that dependencies are compiled for the correct platform.

2. **Binary Dependencies**: Some Python packages (like Pillow and numpy in this project) include native components that must be compiled specifically for the target platform. Installing these on your local machine would compile them for the wrong platform.

...

### Why Not Just Build the Libraries Locally?

Attempting to install dependencies like Pillow locally on macOS or Windows and then zipping them often results in runtime errors such as `Runtime.ImportModuleError` or `No module named 'PIL'`. This happens because these libraries include native extensions compiled for your local OS, which are incompatible with the Amazon Linux environment used by AWS Lambda. Docker solves this by mimicking the Lambda runtime, ensuring that all compiled binaries and dependencies are compatible. Therefore, using Docker is the only reliable method to avoid unexpected import failures and timeout errors in production.

3. **Runtime Match**: The Docker image (`amazon/aws-sam-cli-build-image-python3.9:latest`) exactly matches the Lambda runtime environment, ensuring complete compatibility.

Without Docker, locally installed packages might work on your machine but fail when deployed to Lambda, especially for packages with native extensions.

## IAM Permissions

The Lambda function has permissions to:

- Read from SQS queue
- Get and Put objects in S3
- Write CloudWatch logs

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Note

Remember to replace the wildcard S3 bucket permissions (`arn:aws:s3:::*/*`) with specific bucket ARNs in production environments for better security.
