#! /usr/bin/bash

BUCKET=$(terraform output -raw bucket_name)
echo "BUCKET: $BUCKET"
echo 'Hello from lambda.sh' > hello.txt

aws s3 rm s3://$BUCKET/lambda/hello.txt
aws s3 cp ./hello.txt s3://$BUCKET/lambda/hello.txt