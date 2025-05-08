import boto3


def delete_all_buckets():
    """Delete all S3 buckets in the account"""
    s3 = boto3.client("s3")

    try:
        response = s3.list_buckets()

        if not response["Buckets"]:
            print("No buckets found to delete")
            return True

        success = True
        for bucket in response["Buckets"]:
            bucket_name = bucket["Name"]
            print(f"Attempting to delete bucket: {bucket_name}")

            try:
                # Check if bucket is versioned
                versioning = s3.get_bucket_versioning(Bucket=bucket_name)
                is_versioned = versioning.get("Status") == "Enabled"

                if is_versioned:
                    # Delete all versions and delete markers
                    paginator = s3.get_paginator("list_object_versions")
                    for page in paginator.paginate(Bucket=bucket_name):
                        # Delete versions
                        if "Versions" in page:
                            for version in page["Versions"]:
                                s3.delete_object(
                                    Bucket=bucket_name,
                                    Key=version["Key"],
                                    VersionId=version["VersionId"],
                                )
                        # Delete delete markers
                        if "DeleteMarkers" in page:
                            for marker in page["DeleteMarkers"]:
                                s3.delete_object(
                                    Bucket=bucket_name,
                                    Key=marker["Key"],
                                    VersionId=marker["VersionId"],
                                )
                else:
                    # Delete all objects in non-versioned bucket
                    paginator = s3.get_paginator("list_objects_v2")
                    for page in paginator.paginate(Bucket=bucket_name):
                        if "Contents" in page:
                            for obj in page["Contents"]:
                                s3.delete_object(Bucket=bucket_name, Key=obj["Key"])

                print(f"All objects in bucket {bucket_name} deleted successfully")

                # Delete the bucket
                s3.delete_bucket(Bucket=bucket_name)
                print(f"Bucket {bucket_name} deleted successfully")
            except Exception as delete_error:
                print(f"Error deleting bucket {bucket_name}: {delete_error}")
                success = False

        return success

    except Exception as e:
        print(f"Error listing buckets: {e}")
        return False


if __name__ == "__main__":
    delete_all_buckets()
