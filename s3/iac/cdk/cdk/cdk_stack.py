from aws_cdk import (
    Stack,
)
from constructs import Construct
from aws_cdk import aws_s3 as s3
from aws_cdk import RemovalPolicy
from aws_cdk import aws_iam as iam


# Note
# Before running cdk bootstrap/ deploy, make sure to grant admin access to your user
# 1.	Go to IAM in AWS Console
# 2.	Click Users → Select user danyelkoca
# 3.	Go to the Permissions tab
# 4.	Click Add permissions
# 5.	Choose Attach policies directly
# 6.	In the search bar, type AdministratorAccess
# 7.	Check the box next to AdministratorAccess
# 8.	Click Next: Review, then Add permissions


class CdkStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        bucket = s3.Bucket(
            self,
            "Bucket",
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            encryption=s3.BucketEncryption.S3_MANAGED,
            enforce_ssl=True,
            versioned=False,
            removal_policy=RemovalPolicy.RETAIN,
        )

        role = iam.Role(
            self,
            "MyExampleRole",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
            description="Example role for EC2 with S3 read access",
        )

        role.add_to_policy(
            iam.PolicyStatement(
                actions=["s3:GetObject"], resources=[f"{bucket.bucket_arn}/*"]
            )
        )

        # The code that defines your stack goes here

        # example resource
        # queue = sqs.Queue(
        #     self, "CdkQueue",
        #     visibility_timeout=Duration.seconds(300),
        # )
