#! /usr/bin/bash

echo "Creating S3 bucket..."

if [ "$#" -lt 1 ]; then
    echo "This script requires at least one argument. You must provide a bucket name. Usage: $(basename "$0") <bucket-name> [region]"
    exit 1
fi

BUCKET_NAME="$1"
REGION="${2:-ap-northeast-1}"

# Check if bucket already exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists. Skipping creation."
else
    LOCATION=$(aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" \
        --region "$REGION" \
        --query Location \
        --output text)
    
    echo "S3 bucket $BUCKET_NAME created in region $REGION."
    echo "Bucket location: $LOCATION"
fi