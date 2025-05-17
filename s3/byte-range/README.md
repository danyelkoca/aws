# AWS S3 Byte Range Access Example

## Create a new file

The following command creates a new text file named `hello.txt` with sample Lorem Ipsum content.

```bash
echo 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' > hello.txt
```

## Create a new S3 bucket

This command creates a new Amazon S3 bucket named `<BUCKET_NAME>`.

```bash
aws s3 mb s3://<BUCKET_NAME>
```

## Upload the file to S3

Upload the local file `hello.txt` to the S3 bucket under the same name.

```bash
aws s3 cp hello.txt s3://<BUCKET_NAME>/hello.txt
```

## Get byte size of the file in S3

Retrieve metadata about the uploaded file, including its size in bytes.

```bash
aws s3api head-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt
```

**Output:**

```json
{
  "AcceptRanges": "bytes",
  "LastModified": "2025-05-17T03:09:47+00:00",
  "ContentLength": 445,
  "ETag": "\"39d08e040fcdbab6ebc9ad791c50fbac\"",
  "ContentType": "text/plain",
  "ServerSideEncryption": "AES256",
  "Metadata": {}
}
```

The file has a size of 445 bytes.

## Read the first 100 bytes of the file

Use byte-range retrieval to download only the first 100 bytes of the file from S3.

```bash
aws s3api get-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt \
    --range bytes=0-99 \
    hello_first.txt
```

**Output:**

```json
{
  "AcceptRanges": "bytes",
  "LastModified": "2025-05-17T03:09:47+00:00",
  "ContentLength": 100,
  "ETag": "\"39d08e040fcdbab6ebc9ad791c50fbac\"",
  "ContentRange": "bytes 0-99/445",
  "ContentType": "text/plain",
  "ServerSideEncryption": "AES256",
  "Metadata": {}
}
```

Contents of `hello_first.txt`:

```text
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore
```

## Read the last 100 bytes of the file

Retrieve the last 100 bytes of the file using a negative byte range.

```bash
aws s3api get-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt \
    --range bytes=-100 \
    hello_last.txt
```

Contents of `hello_last.txt`:

```text
sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum
```

# Working with Byte Range Fetches in S3

This guide demonstrates how to use byte range fetches to retrieve specific parts of an S3 object.

## Prerequisites

- AWS CLI installed and configured
- Basic understanding of AWS S3 concepts

## Create a Bucket and Upload a File

### Step 1: Create an S3 Bucket

This command creates a new Amazon S3 bucket named `<BUCKET_NAME>`.

```bash
aws s3 mb s3://<BUCKET_NAME>
```

### Step 2: Create a Sample File

```bash
echo "Hello World! This is a sample text file for demonstrating byte range fetches." > hello.txt
```

### Step 3: Upload the File to S3

```bash
aws s3 cp hello.txt s3://<BUCKET_NAME>/hello.txt
```

## Retrieving Specific Byte Ranges

### Example 1: Retrieve the First 5 Bytes

To get only the first 5 bytes of the file (which should be "Hello"):

```bash
aws s3api get-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt \
    --range "bytes=0-4" \
    hello_first.txt
```

Verify the content:

```bash
cat hello_first.txt
```

Output:

```
Hello
```

### Example 2: Retrieve the Last 10 Bytes

To get only the last 10 bytes of the file:

```bash
# First, get the object size
FILE_SIZE=$(aws s3api head-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt \
    --query ContentLength \
    --output text)

# Then retrieve the last 10 bytes
aws s3api get-object \
    --bucket <BUCKET_NAME> \
    --key hello.txt \
    --range "bytes=$((FILE_SIZE-10))-$((FILE_SIZE-1))" \
    hello_last.txt
```

Verify the content:

```bash
cat hello_last.txt
```

Output (will vary based on your sample text):

```
fetches.
```

## Use Cases for Byte Range Fetches

1. **Resumable Downloads**: Start downloading from where a previous download was interrupted
2. **Parallel Processing**: Download different parts of a large file in parallel
3. **Partial Content Access**: Retrieve only the needed portion of a file (e.g., headers)
4. **Preview Generation**: Get just enough data to generate a preview
5. **Multimedia Streaming**: Load portions of audio/video files as needed
