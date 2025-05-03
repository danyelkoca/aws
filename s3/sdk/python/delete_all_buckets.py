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
                # Delete all objects in the bucket first
                objects = s3.list_objects_v2(Bucket=bucket_name)
                if "Contents" in objects:
                    for obj in objects["Contents"]:
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
