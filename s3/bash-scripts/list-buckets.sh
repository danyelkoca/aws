#! /usr/bin/bash

set -e

echo "Listing S3 buckets..."

aws s3api list-buckets --output json --no-cli-pager | jq -r '.Buckets | sort_by(.CreationDate) | reverse[] | .Name'