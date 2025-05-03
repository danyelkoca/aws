import boto3
import argparse


def delete_bucket(bucket_name, region="ap-northeast-1"):
    """Delete an S3 bucket if it exists"""
    print(f"Attempting to delete bucket: {bucket_name}")
    s3 = boto3.client("s3", region_name=region)

    try:
        # Check if bucket exists
        s3.head_bucket(Bucket=bucket_name)

        # Delete all objects in the bucket first
        try:
            # Delete all object versions (handles versioned buckets)
            paginator = s3.get_paginator("list_object_versions")
            for page in paginator.paginate(Bucket=bucket_name):
                # Delete markers
                if "DeleteMarkers" in page:
                    for version in page["DeleteMarkers"]:
                        s3.delete_object(
                            Bucket=bucket_name,
                            Key=version["Key"],
                            VersionId=version["VersionId"],
                        )
                # Versions
                if "Versions" in page:
                    for version in page["Versions"]:
                        s3.delete_object(
                            Bucket=bucket_name,
                            Key=version["Key"],
                            VersionId=version["VersionId"],
                        )

            # Also delete objects without versions
            objects = s3.list_objects_v2(Bucket=bucket_name)
            if "Contents" in objects:
                for obj in objects["Contents"]:
                    s3.delete_object(Bucket=bucket_name, Key=obj["Key"])
                print(f"All objects in bucket {bucket_name} deleted successfully")

            # Delete the bucket
            s3.delete_bucket(Bucket=bucket_name)
            print(f"Bucket {bucket_name} deleted successfully")
            return True
        except s3.exceptions.ClientError as delete_error:
            print(f"Error deleting bucket: {delete_error}")
            return False

    except s3.exceptions.ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "404":
            print(f"Bucket {bucket_name} does not exist, nothing to delete")
            return True
        elif error_code == "403":
            print(
                f"Error 403: You don't have permission to access bucket '{bucket_name}'."
            )
            return False
        else:
            print(f"Error checking bucket: {e}")
            return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete an S3 bucket")
    parser.add_argument("bucket_name", help="Name of the S3 bucket to delete")
    parser.add_argument(
        "--region",
        default="ap-northeast-1",
        help="AWS region (default: ap-northeast-1)",
    )

    args = parser.parse_args()
    delete_bucket(args.bucket_name, args.region)
