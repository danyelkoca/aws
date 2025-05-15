#!/bin/bash

# This script retrieves an object from an S3 bucket

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <bucket-name> <object-key>"
  exit 1
fi

BUCKET_NAME=$1
OBJECT_KEY=$2

# Retrieve the object from the S3 bucket
aws s3api get-object --bucket "$BUCKET_NAME" --key "$OBJECT_KEY" "$OBJECT_KEY"

if [ $? -eq 0 ]; then
  echo "Object '$OBJECT_KEY' successfully retrieved from bucket '$BUCKET_NAME'."
else
  echo "Failed to retrieve object '$OBJECT_KEY' from bucket '$BUCKET_NAME'."
fi