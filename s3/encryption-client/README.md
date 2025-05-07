# Client-Side Encryption with Amazon S3

This project focuses on implementing client-side encryption when interacting with Amazon S3.

## Note on Python SDK Support

Client-side encryption can be implemented using the AWS SDKs. However, as of now, the AWS SDK for Python (boto3) does not support the S3 Encryption Client used in other languages. While the AWS Encryption SDK for Python exists, it is not compatible with the Amazon S3 Encryption Client because they produce ciphertexts with different data formats.

See: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingClientSideEncryption.html

Due to this limitation, this project does not include a working example of S3 client-side encryption in Python.