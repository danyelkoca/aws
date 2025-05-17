#!/bin/bash

echo "S3 Versioning Tutorial"
echo "====================="
echo

# Section 1: Setup
echo "1. Setting up versioned bucket"
echo "------------------------------"
## Create a bucket with versioning
aws s3 mb s3://<BUCKET_NAME> && aws s3api put-bucket-versioning --bucket <BUCKET_NAME> --versioning-configuration Status=Enabled

## Check versioning configuration
aws s3api get-bucket-versioning --bucket <BUCKET_NAME>

## Output
# {
#     "Status": "Enabled"
# }

# Section 2: Creating and uploading files
echo
echo "2. Creating and uploading files"
echo "-----------------------------"
## Create files
echo "test1" > test1.txt
echo "test2" > test2.txt
echo "test3" > test3.txt

## Upload files to the bucket with same key
aws s3 cp test1.txt s3://<BUCKET_NAME>/test.txt
aws s3 cp test2.txt s3://<BUCKET_NAME>/test.txt
aws s3 cp test3.txt s3://<BUCKET_NAME>/test.txt

# Section 3: Examining versions
echo
echo "3. Examining versions"
echo "-------------------"
## Check version objects with their content
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "Versions[].{VersionId: VersionId, Type: 'File', IsLatest: IsLatest}" --output json
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "DeleteMarkers[].{VersionId: VersionId, Type: 'DeleteMarker', IsLatest: IsLatest}" --output json

## Output
# [
#     {
#         "VersionId": "abc123...",
#         "Type": "File",
#         "IsLatest": true
#     },
#     {
#         "VersionId": "def456...",
#         "Type": "File",
#         "IsLatest": false
#     },
#     {
#         "VersionId": "ghi789...",
#         "Type": "File",
#         "IsLatest": false
#     }
# ]
# null

## Get the latest version content and print in terminal
aws s3api get-object --bucket <BUCKET_NAME> --key test.txt outfile && cat outfile

## Output
# {
#     "VersionId": "abc123...",
#     "ContentType": "text/plain",
#     "ContentLength": 6
# }
# test3

# Section 4: Deleting and restoring
echo
echo "4. Deleting and restoring objects"
echo "------------------------------"
## Now lets delete the latest version
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt

## Output
# {
#     "DeleteMarker": true,
#     "VersionId": "xyz789..."
# }

## Get the file again
aws s3api get-object --bucket <BUCKET_NAME> --key test.txt outfile && cat outfile

## Output
# An error occurred (NoSuchKey) when calling the GetObject operation: The specified key does not exist.

## This is because the latest version is deleted
## Lets check all versions again
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "Versions[].{VersionId: VersionId, Type: 'File', IsLatest: IsLatest}" --output json
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "DeleteMarkers[].{VersionId: VersionId, Type: 'DeleteMarker', IsLatest: IsLatest}" --output json

## Output
# [
#     {
#         "VersionId": "abc123...",
#         "Type": "File",
#         "IsLatest": false
#     },
#     {
#         "VersionId": "def456...",
#         "Type": "File",
#         "IsLatest": false
#     },
#     {
#         "VersionId": "ghi789...",
#         "Type": "File",
#         "IsLatest": false
#     }
# ]
# [
#     {
#         "VersionId": "xyz789...",
#         "Type": "DeleteMarker",
#         "IsLatest": true
#     }
# ]

## Get the deleted version
## We can't get a delete marker directly - we need to get the versionId of the deleted version
## Let's get the most recent non-deleted version
aws s3api get-object --bucket <BUCKET_NAME> --key test.txt --version-id abc123... outfile && cat outfile

## Now delete the delete marker to restore the file
aws s3api delete-object --bucket <BUCKET_NAME> --key test.txt --version-id xyz789...

## Try getting the object again
aws s3api get-object --bucket <BUCKET_NAME> --key test.txt outfile && cat outfile

## Output
# {
#     "VersionId": "abc123...",
#     "ContentType": "text/plain",
#     "ContentLength": 6
# }
# test3

## Check the versions again
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "Versions[].{VersionId: VersionId, Type: 'File', IsLatest: IsLatest}" --output json
aws s3api list-object-versions --bucket <BUCKET_NAME> --query "DeleteMarkers[].{VersionId: VersionId, Type: 'DeleteMarker', IsLatest: IsLatest}" --output json

## Output
# [
#     {
#         "VersionId": "abc123...",
#         "Type": "File",
#         "IsLatest": true
#     },
#     {
#         "VersionId": "def456...",
#         "Type": "File",
#         "IsLatest": false
#     },
#     {
#         "VersionId": "ghi789...",
#         "Type": "File",
#         "IsLatest": false
#     }
# ]
# []

## There is a version with IsLatest = true
## There are no delete markers

# Cleanup
echo
echo "Cleaning up..."
rm test1.txt test2.txt test3.txt outfile