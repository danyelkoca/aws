#!/bin/bash

echo "S3 Versioning Basic Commands"
echo "=========================="
echo

# Section 1: Basic Setup
echo "1. Basic Setup"
echo "-------------"
## Create a bucket without versioning
aws s3 mb s3://dannykbucket

## Create and upload a file
echo "test" > test.txt
aws s3 cp test.txt s3://dannykbucket/test.txt

## List bucket contents (doesn't show versions)
aws s3 ls s3://dannykbucket

## List objects with API (still no versions)
aws s3api list-objects --bucket dannykbucket --output json

## Check versions (none yet)
aws s3api list-object-versions --bucket dannykbucket

# Section 2: Enabling Versioning
echo
echo "2. Enabling Versioning"
echo "--------------------"
## Enable versioning
aws s3api put-bucket-versioning --bucket dannykbucket --versioning-configuration Status=Enabled

## Check versioning configuration
aws s3api get-bucket-versioning --bucket dannykbucket

## Output
# {
#     "Status": "Enabled"
# }

## Note: Versioning doesn't apply retroactively to existing files
aws s3api list-object-versions --bucket dannykbucket

# Section 3: Working with Versions
echo
echo "3. Working with Versions"
echo "----------------------"
## Upload a new version
echo "test2" > test2.txt
aws s3 cp test2.txt s3://dannykbucket/test.txt

## List versions
aws s3api list-object-versions --bucket dannykbucket --query "Versions[].VersionId"

## Output
# [
#     "abc123...",
#     "null"
# ]

## Get latest version (no version ID specified)
aws s3api get-object --bucket dannykbucket --key test.txt outfile && cat outfile

## Output
# {
#     "VersionId": "abc123...",
#     "ContentType": "text/plain",
#     "ContentLength": 6
# }
# test2

## Get specific version
aws s3api get-object --bucket dannykbucket --key test.txt outfile --version-id abc123... && cat outfile

## Get null version (pre-versioning)
aws s3api get-object --bucket dannykbucket --key test.txt outfile --version-id null && cat outfile

## Output
# {
#     "VersionId": "null",
#     "ContentType": "text/plain",
#     "ContentLength": 5
# }
# test

# Section 4: Deleting Versions
echo
echo "4. Deleting Versions"
echo "------------------"
## Delete a specific version
aws s3api delete-object --bucket dannykbucket --key test.txt --version-id abc123...

## Output
# {
#     "VersionId": "abc123..."
# }

## Check remaining versions
aws s3api list-object-versions --bucket dannykbucket --query "Versions[].VersionId"

## Output
# [
#     "null"
# ]

# Cleanup
echo
echo "Cleaning up..."
# Delete all versions first
aws s3api delete-objects --bucket dannykbucket --delete "$(aws s3api list-object-versions --bucket dannykbucket --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws s3api delete-objects --bucket dannykbucket --delete "$(aws s3api list-object-versions --bucket dannykbucket --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Now we can remove the bucket
aws s3 rb s3://dannykbucket --force
rm test.txt test2.txt outfile

