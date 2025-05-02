import boto3


def list_buckets():
    """List all S3 buckets in the AWS account"""
    print("Listing all S3 buckets:")
    s3 = boto3.client("s3")

    try:
        # Get list of buckets
        response = s3.list_buckets()

        # Print bucket information
        if "Buckets" in response and response["Buckets"]:
            print(f"Found {len(response['Buckets'])} buckets:")
            for bucket in response["Buckets"]:
                print(f"  - {bucket['Name']} (created: {bucket['CreationDate']})")
            return True
        else:
            print("No buckets found in the account")
            return True

    except s3.exceptions.ClientError as e:
        print(f"Error listing buckets: {e}")
        return False


if __name__ == "__main__":
    list_buckets()
