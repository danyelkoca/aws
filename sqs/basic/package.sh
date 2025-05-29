#!/bin/zsh

# Create a temporary directory for packaging
mkdir -p package

# Copy the Lambda function and requirements.txt
cp index.py package/
cp requirements.txt package/

# Install dependencies in the correct structure using Docker
docker run --rm \
    -v "$PWD"/package:/var/task \
    amazon/aws-sam-cli-build-image-python3.9:latest \
    /bin/sh -c "pip install -r /var/task/requirements.txt --target /var/task"

# Create the ZIP file from the package directory
cd package
zip -r ../lambda_function_payload.zip .
cd ..

# Clean up
rm -rf package

echo "Lambda function has been packaged into lambda_function_payload.zip"
