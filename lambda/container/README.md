# Container-based AWS Lambda Function

This project demonstrates how to create and deploy a containerized AWS Lambda function using AWS SAM (Serverless Application Model).

## Project Overview

The function generates fake user data using the Python `Faker` library and returns it through an API Gateway endpoint.

### Project Structure

```
.
├── .gitignore          # Git ignore file for Python, SAM, and IDE files
├── Dockerfile          # Container definition for Lambda
├── README.md          # This file
├── app.py             # Lambda function code
├── requirements.txt    # Python dependencies
├── samconfig.toml     # SAM CLI configuration
└── template.yaml      # SAM template defining AWS resources
```

### Technologies Used

- **AWS SAM**: Infrastructure as Code (IaC) framework for serverless applications
- **Docker**: Containerization platform
- **Amazon ECR**: Container registry service
- **AWS Lambda**: Serverless compute service
- **API Gateway**: Managed API service
- **Python 3.12**: Programming language
- **Faker**: Library for generating fake data

## How It Works

1. The Lambda function (`app.py`) uses the Faker library to generate random user data
2. The function is packaged in a container using the Dockerfile
3. AWS SAM builds and deploys the container to Amazon ECR
4. The container is then used as the Lambda function runtime
5. API Gateway provides an HTTP endpoint to invoke the function

### Container Details

The Dockerfile uses the official AWS Lambda Python base image:

- `public.ecr.aws/lambda/python:3.12`
- Includes the AWS Lambda Runtime Interface Client
- Optimized for Lambda execution environment

### Amazon ECR (Elastic Container Registry)

ECR is AWS's container registry service that:

- Stores, manages, and deploys container images
- Integrates with IAM for access control
- Automatically encrypts images at rest
- Provides vulnerability scanning

## Development and Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed and running
- AWS SAM CLI installed
- Python 3.12 installed

### ECR Authentication

Before deploying, authenticate Docker with Amazon ECR:

```bash
# Get the AWS account ID
export AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# Get the ECR registry URL
export ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Authenticate Docker with ECR (valid for 12 hours)
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
```

### Local Development

1. Install dependencies:
   \`\`\`bash
   pip install -r requirements.txt
   \`\`\`

2. Test locally:
   \`\`\`bash
   sam build
   sam local invoke

# or

sam local start-api
\`\`\`

### Deployment

Deploy to AWS:
\`\`\`bash
sam build
sam deploy --guided
\`\`\`

### Cleanup

To remove all resources created by this project, you have two options:

1. Using SAM CLI:

```bash
sam delete
```

2. Using AWS CloudFormation directly:

```bash
aws cloudformation delete-stack --stack-name aws-sam-cli-managed-default
```

After deleting the stack, clean up the ECR repository and S3 bucket:

```bash
# Delete the ECR repository
aws ecr delete-repository --repository-name container-lambda --force

# Delete the S3 bucket used by SAM for deployment artifacts
# Replace BUCKET_NAME with your bucket name from samconfig.toml (e.g., aws-sam-cli-managed-default)
# First, remove all objects and versions from the bucket
aws s3api delete-objects \
    --bucket BUCKET_NAME \
    --delete "$(aws s3api list-object-versions \
        --bucket BUCKET_NAME \
        --output json \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Then delete the empty bucket
aws s3 rb s3://BUCKET_NAME --force
```

Note: The S3 bucket name can be found in your `samconfig.toml` file under the `s3_bucket` parameter.

## API Usage

Send a GET request to the API endpoint:
\`\`\`bash
curl https://[your-api-id].execute-api.[region].amazonaws.com/Prod/generate
\`\`\`

Response format:
\`\`\`json
{
"name": "John Doe",
"email": "john.doe@example.com",
"address": "123 Main St, City, Country",
"job": "Software Engineer",
"company": "Tech Corp",
"phone_number": "(555) 123-4567"
}
\`\`\`

## Implementation Notes

1. **ARM64 Architecture**: The function is configured for ARM64 architecture for better price/performance on AWS Lambda
2. **Container Optimization**: The base image is specifically optimized for Lambda execution
3. **Cold Start Consideration**: Container-based functions may have longer cold starts than regular Lambda functions
4. **Image Size**: The container image is optimized to include only necessary dependencies

## Lessons Learned

1. **Project Structure**: Keep Dockerfile at the root level with SAM template for better build context
2. **ECR Authentication**: Proper ECR authentication is crucial for deployment
3. **Architecture Choice**: ARM64 provides better price/performance ratio
4. **Base Image**: Using AWS-provided base images simplifies Lambda container development

## Resources

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [AWS Lambda Container Documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html)
- [Amazon ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [AWS Lambda Python Runtime](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)

## Troubleshooting

### Common ECR Issues

1. **Authentication Error**

   ```
   Error: Cannot perform an interactive login from a non TTY device
   ```

   Solution: Make sure you're running the docker login command with proper AWS credentials and region set.

2. **Push Failed**

   ```
   Repository not found or access denied
   ```

   Solution: Verify that:

   - The ECR repository exists
   - You have proper IAM permissions
   - You're using the correct AWS region

3. **Docker Build Issues**

   ```
   no space left on device
   ```

   Solution: Clean up unused Docker resources:

   ```bash
   # Remove unused containers
   docker container prune

   # Remove unused images
   docker image prune

   # Remove build cache
   docker builder prune
   ```

4. **ARM64 Compatibility**
   If you're building on an x86 machine for ARM64:
   - Use Docker's buildx feature
   - Add `--platform linux/arm64` to your docker build command
   - Or set the correct platform in your SAM template

### Common SAM Deploy Issues

1. **Timeout During Deployment**

   - Increase the timeout in your `template.yaml`
   - Check your internet connection
   - Verify ECR push permissions

2. **Memory Issues**
   - Adjust the memory allocation in `template.yaml`
   - Monitor Lambda function metrics in CloudWatch

For additional help, check CloudWatch logs or run `sam logs` to debug your function.
