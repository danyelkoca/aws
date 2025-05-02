import boto3
import argparse


def list_objects(bucket_name):
    """List all objects in an S3 bucket"""
    print(f"Listing objects in bucket: {bucket_name}")
    s3 = boto3.client("s3")

    try:
        # Check if bucket exists
        s3.head_bucket(Bucket=bucket_name)

        # List objects in the bucket
        try:
            objects = s3.list_objects_v2(Bucket=bucket_name)
            if "Contents" in objects:
                print(f"Objects in bucket {bucket_name}:")
                for obj in objects["Contents"]:
                    print(f"  - {obj['Key']} ({obj['Size']} bytes)")
                print(f"Total: {len(objects['Contents'])} objects")
            else:
                print(f"Bucket {bucket_name} is empty")
            return True
        except s3.exceptions.ClientError as list_error:
            print(f"Error listing objects: {list_error}")
            return False

    except s3.exceptions.ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "404":
            print(f"Bucket {bucket_name} does not exist")
            return False
        elif error_code == "403":
            print(
                f"Error 403: You don't have permission to access bucket '{bucket_name}'."
            )
            return False
        else:
            print(f"Error checking bucket: {e}")
            return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="List objects in an S3 bucket")
    parser.add_argument(
        "bucket_name", help="Name of the S3 bucket to list objects from"
    )

    args = parser.parse_args()
    list_objects(args.bucket_name)
