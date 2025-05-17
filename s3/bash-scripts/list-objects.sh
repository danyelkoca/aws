#! /usr/bin/bash

echo "Listing S3 bucket objects..."

if [ "$#" -lt 1 ]; then
    echo "This script requires at least one argument. You must provide a bucket name. Usage: $(basename "$0") <bucket-name> [region] [prefix]"
    exit 1
fi

BUCKET_NAME="$1"
REGION="${2:-<DEFAULT_REGION>}"
PREFIX="${3:-}"

# Check if the bucket exists before proceeding
echo "Checking if bucket $BUCKET_NAME exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    # List all objects in the bucket
    echo "Listing objects from bucket $BUCKET_NAME..."
    if [ -z "$PREFIX" ]; then
        aws s3 ls s3://$BUCKET_NAME --recursive --region "$REGION"
    else
        echo "Using prefix: $PREFIX"
        aws s3 ls s3://$BUCKET_NAME/$PREFIX --recursive --region "$REGION"
    fi
    
    echo "Objects in S3 bucket $BUCKET_NAME in region $REGION have been listed."
else
    echo "Bucket $BUCKET_NAME does not exist in region $REGION."
    exit 1
fi