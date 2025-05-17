#! /usr/bin/bash

echo "Deleting objects from S3 bucket..."

if [ "$#" -lt 1 ]; then
    echo "This script requires at least one argument. You must provide a bucket name. Usage: $(basename "$0") <bucket-name> [region]"
    exit 1
fi

BUCKET_NAME="$1"
REGION="${2:-<DEFAULT_REGION>}"

# Check if the bucket exists before proceeding
echo "Checking if bucket $BUCKET_NAME exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    # Remove all objects in the bucket
    echo "Removing all objects from bucket $BUCKET_NAME..."
    aws s3 rm s3://$BUCKET_NAME --recursive --region "$REGION"
    
    echo "All objects in bucket $BUCKET_NAME have been deleted from region $REGION."
else
    echo "Bucket $BUCKET_NAME does not exist in region $REGION."
    exit 0
fi
