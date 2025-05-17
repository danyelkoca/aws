# AWS S3 Multipart Upload Example

---

## Step 1: Create a Directory and a Large File

```bash
# Create the directory to hold large files
mkdir -p largefiles

# Create a 50MB file filled with zeros
dd if=/dev/zero of=largefiles/largefile.txt bs=1M count=50
```

---

## Step 2: Check File Size

```bash
# List the file details to verify the size
ls -lah largefiles/*.txt
```

Output example:

```
-rw-r--r-- 1 danyelkoca staff 50M May 17 11:15 largefiles/largefile.txt
```

---

## Step 3: Create an S3 Bucket

```bash
# Create a new S3 bucket named 'dannykbucket'
aws s3 mb s3://dannykbucket
```

---

## Step 4: Initiate a Multipart Upload

```bash
# Start a multipart upload for 'largefile.txt' in the bucket
aws s3api create-multipart-upload --bucket dannykbucket --key largefile.txt
```

---

## Step 5: Check the Multipart Upload Status

```json
{
  "Uploads": [
    {
      "UploadId": "<UPLOAD_ID>",
      "Key": "largefile.txt",
      "Initiated": "2025-05-17T02:16:49+00:00",
      "StorageClass": "STANDARD",
      "Owner": {
        "DisplayName": "koca.danyel",
        "ID": "<REDACTED>"
      },
      "Initiator": {
        "ID": "<REDACTED>",
        "DisplayName": "danyelkoca"
      }
    }
  ],
  "RequestCharged": null,
  "Prefix": null
}
```

---

## Step 6: Retrieve the Upload ID

```bash
# Get the upload ID for the multipart upload
aws s3api list-multipart-uploads --bucket dannykbucket --query 'Uploads[0].UploadId' --output text
```

Example output (redacted):

```
2LcjCj2ZYwuDGrLtun4pybEhk_Edw9QYONY5jLpwtGrRCjkhCl65eOZ0Ey88_aXJT31WOw_vfdEHgUwnBA88rC2HHWFIhltbnbT8Cc7PgiPVGyaVx.v9iDIFpa.vT3CyNQQJtWnOMSJl_ip6dKXYQw--
```

---

## Step 7: Split the File into Parts

```bash
# Create a directory to store the split files
mkdir -p largefiles/split-files

# Split the large file into 10MB chunks for upload
split -b 10M largefiles/largefile.txt largefiles/split-files/part-
```

---

## Step 8: Upload Each Part

```bash
# Set the upload ID variable (replace <UPLOAD_ID> with actual ID)
UPLOAD_ID="<UPLOAD_ID>"

# Upload part 1
aws s3api upload-part \
    --bucket dannykbucket \
    --key largefile.txt \
    --part-number 1 \
    --body largefiles/split-files/part-aa \
    --upload-id "$UPLOAD_ID"

# Upload part 2
aws s3api upload-part \
    --bucket dannykbucket \
    --key largefile.txt \
    --part-number 2 \
    --body largefiles/split-files/part-ab \
    --upload-id "$UPLOAD_ID"

# Upload part 3
aws s3api upload-part \
    --bucket dannykbucket \
    --key largefile.txt \
    --part-number 3 \
    --body largefiles/split-files/part-ac \
    --upload-id "$UPLOAD_ID"

# Upload part 4
aws s3api upload-part \
    --bucket dannykbucket \
    --key largefile.txt \
    --part-number 4 \
    --body largefiles/split-files/part-ad \
    --upload-id "$UPLOAD_ID"

# Upload part 5
aws s3api upload-part \
    --bucket dannykbucket \
    --key largefile.txt \
    --part-number 5 \
    --body largefiles/split-files/part-ae \
    --upload-id "$UPLOAD_ID"
```

---

## Step 9: List Uploaded Parts

```bash
# List all parts uploaded for the multipart upload
aws s3api list-parts \
    --bucket dannykbucket \
    --key largefile.txt \
    --upload-id "$UPLOAD_ID"
```

Example output:

```json
{
  "Parts": [
    {
      "PartNumber": 1,
      "LastModified": "2025-05-17T02:21:29+00:00",
      "ETag": "\"f1c9645dbc14efddc7d8a322685f26eb\"",
      "Size": 10485760
    },
    {
      "PartNumber": 2,
      "LastModified": "2025-05-17T02:22:15+00:00",
      "ETag": "\"f1c9645dbc14efddc7d8a322685f26eb\"",
      "Size": 10485760
    },
    {
      "PartNumber": 3,
      "LastModified": "2025-05-17T02:22:20+00:00",
      "ETag": "\"f1c9645dbc14efddc7d8a322685f26eb\"",
      "Size": 10485760
    },
    {
      "PartNumber": 4,
      "LastModified": "2025-05-17T02:22:28+00:00",
      "ETag": "\"f1c9645dbc14efddc7d8a322685f26eb\"",
      "Size": 10485760
    },
    {
      "PartNumber": 5,
      "LastModified": "2025-05-17T02:22:34+00:00",
      "ETag": "\"f1c9645dbc14efddc7d8a322685f26eb\"",
      "Size": 10485760
    }
  ],
  "ChecksumAlgorithm": null,
  "Initiator": {
    "ID": "<REDACTED>",
    "DisplayName": "danyelkoca"
  },
  "Owner": {
    "DisplayName": "koca.danyel",
    "ID": "<REDACTED>"
  },
  "StorageClass": "STANDARD",
  "ChecksumType": null
}
```

---

## Step 10: Complete the Multipart Upload

```bash
# Complete the multipart upload by assembling all uploaded parts
aws s3api complete-multipart-upload \
    --bucket dannykbucket \
    --key largefile.txt \
    --upload-id "$UPLOAD_ID" \
    --multipart-upload file://<(aws s3api list-parts --bucket dannykbucket --key largefile.txt --upload-id "$UPLOAD_ID" --query '{Parts: Parts[].{PartNumber: PartNumber, ETag: ETag}}' --output json)
```

Example output:

```json
{
  "ServerSideEncryption": "AES256",
  "Location": "https://dannykbucket.s3.ap-northeast-1.amazonaws.com/largefile.txt",
  "Bucket": "dannykbucket",
  "Key": "largefile.txt",
  "ETag": "\"b112a68f6cb4e22726d733bdaf03535a-5\"",
  "ChecksumCRC64NVME": "ZfX5vT9m/o8=",
  "ChecksumType": "FULL_OBJECT"
}
```

---

## Step 11: Verify the Uploaded File

```bash
# List the uploaded file in the bucket to verify size and presence
aws s3 ls s3://dannykbucket/largefile.txt
```

Example output:

```
2025-05-17 11:16:49 52428800 largefile.txt
```

---

## Step 12: Clean Up

```bash
# Remove the uploaded file from the bucket
aws s3 rm s3://dannykbucket/largefile.txt

# Remove the bucket itself (force deletes all objects)
aws s3 rb s3://dannykbucket --force
```

---
