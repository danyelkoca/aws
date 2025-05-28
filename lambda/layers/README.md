# AWS Lambda Layers Example

## What are Lambda Layers?

AWS Lambda Layers are a way to package and share code libraries, custom runtimes, and other dependencies across multiple Lambda functions. Instead of including these dependencies in each function's deployment package, you can attach them as layers, which helps to:

1. **Reduce Deployment Package Size**: Keep your function code small by moving large dependencies to layers
2. **Share Code**: Reuse common code across multiple functions
3. **Separate Concerns**: Manage dependencies independently from function code
4. **Version Control**: Update shared code without modifying function code

### Common Use Cases

- **Shared Libraries**: Utility functions, helper classes, and common business logic
- **Large Dependencies**: ML libraries (numpy, pandas, tensorflow), image processing libraries
- **Custom Runtime Dependencies**: FFmpeg, ImageMagick, or other binaries
- **SDK and Framework Dependencies**: AWS SDK, database connectors
- **Monitoring Tools**: Custom monitoring, logging, or tracing libraries

### Key Benefits

- **Faster Deployments**: Smaller function packages deploy faster
- **Simplified Dependency Management**: Update shared code in one place
- **Better Organization**: Separate function code from dependencies
- **Cost Efficiency**: Layers are counted only once for simultaneous executions
- **Version Control**: Each layer can have multiple versions

This project demonstrates how to use AWS Lambda Layers with SAM (Serverless Application Model). It includes a simple utility layer and a Lambda function that uses it.

## Project Structure

```
.
├── layers/
│   └── utils/
│       └── python/
│           └── utils/
│               └── helper.py    # Utility functions in the layer
├── src/
│   └── app.py                  # Lambda function code
├── template.yaml               # SAM template
├── samconfig.toml             # SAM CLI configuration
└── README.md                  # This file
```

## How It Works

1. The project defines a Lambda Layer (`UtilsLayer`) containing utility functions
2. The Lambda function imports and uses functions from the layer
3. When deployed, SAM builds and packages both the layer and function

## Layer Structure

The layer follows the required AWS Lambda layer structure:

- `python/` directory contains the Python packages
- Module `utils` with utility functions
- Functions can be imported in Lambda as `from utils.helper import format_greeting`

## Development

1. Install dependencies (if any):

```bash
pip install -r requirements.txt
```

2. Test locally:

```bash
sam build
sam local invoke
```

3. Deploy to AWS:

```bash
sam build
sam deploy --guided
```

## Testing

Send a GET request to the API endpoint:

```bash
curl https://[your-api-id].execute-api.[region].amazonaws.com/Prod/hello
```

Expected response:

```json
{
  "message": "Hello, World! (from Lambda Layer)"
}
```

## Cleanup

You have several options to clean up the resources:

1. Using SAM CLI (recommended):

```bash
sam delete
```

2. Using AWS CloudFormation directly:

```bash
aws cloudformation delete-stack --stack-name lambda-layers-example
aws cloudformation wait stack-delete-complete --stack-name lambda-layers-example
```

3. Clean up remaining resources (if needed):

```bash
# Get your account ID
export AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# Delete the ECR repository if it exists
aws ecr delete-repository --repository-name lambda-layers-example --force || true

# Clean up the S3 bucket used by SAM (replace BUCKET_NAME with your bucket name from samconfig.toml)
aws s3 rb s3://aws-sam-cli-managed-default-samclisourcebucket-XXXXXXXXXXXX --force
```

## Layer Structure Notes

The layer structure is critical for Python Lambda layers:

```
layers/utils/
└── python/           # Required - Lambda adds /opt/python to PYTHONPATH
    └── utils/        # Your package directory
        ├── __init__.py
        └── helper.py
```

Key points about Lambda layers:

1. The `python` directory at the layer root is required by AWS Lambda
2. Lambda automatically adds `/opt/python` to the Python path
3. Your package must be inside the `python` directory
4. The layer is mounted at `/opt` in the Lambda environment
