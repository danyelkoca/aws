#! /usr/bin/bash

echo "Uploading file to S3 bucket..."

if [ "$#" -lt 1 ]; then
    echo "This script requires at least one argument. You must provide a bucket name. Usage: $(basename "$0") <bucket-name> [region] [prefix]"
    exit 1
fi

BUCKET_NAME="$1"
REGION="${2:-ap-northeast-1}"
PREFIX="${3:-files}"
TEMP_DIR=$(mktemp -d)

# Check if the bucket exists before proceeding
echo "Checking if bucket $BUCKET_NAME exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    echo "Creating 1 empty file in $TEMP_DIR..."
    
    
    # Create 1 empty file
    FILENAME="file_1.txt"
    FILEPATH="$TEMP_DIR/$FILENAME"
    
    # Create empty file
    touch "$FILEPATH"
    
    echo "Created $FILENAME (0 bytes)"
    
    # Display directory tree
    echo -e "\nTemporary directory structure:"
    if command -v tree &> /dev/null; then
        tree "$TEMP_DIR"
    else
        ls -la "$TEMP_DIR"
    fi
    
    echo -e "\nSyncing files to bucket $BUCKET_NAME..."
    
    # Sync the directory to S3
    if [ -z "$PREFIX" ]; then
        aws s3 sync "$TEMP_DIR" "s3://$BUCKET_NAME/" --region "$REGION"
    else
        aws s3 sync "$TEMP_DIR" "s3://$BUCKET_NAME/$PREFIX/" --region "$REGION"
    fi
    
    echo "Synced $FILENAME (0 bytes) to s3://$BUCKET_NAME/$PREFIX/$FILENAME"
    
    # Clean up temporary files
    rm -rf "$TEMP_DIR"
    
    echo "Successfully uploaded 1 empty file to S3 bucket $BUCKET_NAME in region $REGION."
else
    echo "Bucket $BUCKET_NAME does not exist in region $REGION."
    exit 1
fi
