# Working with S3 Buckets and Metadata

This guide demonstrates how to create S3 buckets, upload objects, and work with metadata using the AWS CLI.

## Create a Bucket

```bash
aws s3 mb s3://dannykbucket
```

## Prepare a Sample File

```bash
echo "Hello Mars" > hello.txt
```

## Upload a Basic Object

```bash
aws s3api put-object \
    --bucket dannykbucket \
    --key hello.txt \
    --body hello.txt
```

## Upload with Custom Metadata

```bash
aws s3api put-object \
    --bucket dannykbucket \
    --key hellowithmetadata.txt \
    --body hello.txt \
    --metadata planet=Mars
```

## Verify Object Metadata

```bash
aws s3api head-object \
    --bucket dannykbucket \
    --key hellowithmetadata.txt
```

### Example Output

```json
{
        "AcceptRanges": "bytes",
        "LastModified": "2025-05-04T07:20:23+00:00",
        "ContentLength": 11,
        "ETag": "\"8ed2d86f12620cdba4c976ff6651637f\"",
        "ContentType": "binary/octet-stream",
        "ServerSideEncryption": "AES256",
        "Metadata": {
                "planet": "Mars"
        }
}
```