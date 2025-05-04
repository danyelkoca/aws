# Understanding S3 Checksums

This guide demonstrates how to work with checksums when using Amazon S3.

## Creating a Test Bucket

First, create an S3 bucket to store our test files:

```bash
aws s3 mb s3://checksums-examples-ab-23422312
```

## Working with MD5 Checksums

Let's create a test file and calculate its MD5 checksum:

```bash
echo "Hello Mars" > myfile.txt
md5sum myfile.txt
```

Output:
```
8ed2d86f12620cdba4c976ff6651637f  myfile.txt
```

Now upload the file to S3 and examine its ETag, which will match the MD5 checksum:

```bash
aws s3 cp myfile.txt s3://checksums-examples-ab-23422312/myfile.txt
aws s3api head-object --bucket checksums-examples-ab-23422312 --key myfile.txt 
```

Output:
```json
{
    "AcceptRanges": "bytes",
    "LastModified": "2025-05-04T06:08:02+00:00",
    "ContentLength": 11,
    "ETag": "\"8ed2d86f12620cdba4c976ff6651637f\"",
    "ContentType": "text/plain",
    "ServerSideEncryption": "AES256",
    "Metadata": {}
}
```

## Using CRC32 Checksums

S3 also supports other checksum algorithms. Let's create a file and specify a CRC32 checksum:

```bash
# Install rhash if not already available
sudo apt install rhash -y

# Create a test file
echo "Hello Mars" > myfile-crc32.txt

# Calculate CRC32 checksum
rhash --crc32 --simple myfile-crc32.txt
```

Output:
```
e7c80b87  myfile-crc32.txt
```

Upload with explicit checksum verification:

```bash
# First, convert the hex CRC32 to binary and then to base64
CRC32_HEX="e7c80b87"
CRC32_BASE64=$(echo -n $CRC32_HEX | xxd -r -p | base64)

aws s3api put-object \
  --bucket checksums-examples-ab-23422312 \
  --key myfile-crc32.txt \
  --body myfile-crc32.txt \
  --checksum-algorithm="CRC32" \
  --checksum-crc32="$CRC32_BASE64" \
  --no-cli-auto-prompt
```

Output:
```json
{
    "ETag": "\"8ed2d86f12620cdba4c976ff6651637f\"",
    "ChecksumCRC32": "58gLhw==",
    "ChecksumType": "FULL_OBJECT",
    "ServerSideEncryption": "AES256"
}
```