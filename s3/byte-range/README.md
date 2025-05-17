# AWS S3 Byte Range Access Example

## Create a new file

The following command creates a new text file named `hello.txt` with sample Lorem Ipsum content.

```bash
echo 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' > hello.txt
```

## Create a new S3 bucket

This command creates a new Amazon S3 bucket named `dannykbucket`.

```bash
aws s3 mb s3://dannykbucket
```

## Upload the file to S3

Upload the local file `hello.txt` to the S3 bucket under the same name.

```bash
aws s3 cp hello.txt s3://dannykbucket/hello.txt
```

## Get byte size of the file in S3

Retrieve metadata about the uploaded file, including its size in bytes.

```bash
aws s3api head-object \
    --bucket dannykbucket \
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
    --bucket dannykbucket \
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
    --bucket dannykbucket \
    --key hello.txt \
    --range bytes=-100 \
    hello_last.txt
```

Contents of `hello_last.txt`:

```text
sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum
```
