#! /usr/bin/bash

BUCKET=$(terraform output -raw bucket_name)
echo "BUCKET: $BUCKET"
echo 'Hello from queue.sh' > hello.txt

aws s3 rm s3://$BUCKET/queue/hello.txt
aws s3 cp ./hello.txt s3://$BUCKET/queue/hello.txt