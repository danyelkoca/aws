import boto3
import argparse


def create_bucket(bucket_name, region="ap-northeast-1"):
    """Create an S3 bucket if it doesn't exist"""
    print(f"Attempting to create bucket: {bucket_name}")
    s3 = boto3.client("s3")

    try:
        s3.head_bucket(Bucket=bucket_name)
        print(f"Bucket {bucket_name} already exists, skipping creation")
        return True
    except s3.exceptions.ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "404":
            # Bucket doesn't exist, create it
            try:
                s3.create_bucket(
                    Bucket=bucket_name,
                    CreateBucketConfiguration={"LocationConstraint": region},
                )
                print(f"Bucket {bucket_name} created successfully")
                return True
            except s3.exceptions.ClientError as create_error:
                print(f"Error creating bucket: {create_error}")
                return False
        elif error_code == "403":
            print(
                f"Error 403: Bucket '{bucket_name}' already exists but is owned by another AWS account, or you don't have permission to access it."
            )
            return False
        else:
            print(f"Error checking bucket: {e}")
            return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create an S3 bucket")
    parser.add_argument("bucket_name", help="Name of the S3 bucket to create")
    parser.add_argument(
        "--region",
        default="ap-northeast-1",
        help="AWS region (default: ap-northeast-1)",
    )

    args = parser.parse_args()
    create_bucket(args.bucket_name, args.region)
