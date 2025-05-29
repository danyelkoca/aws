import json
import os
import boto3
from PIL import Image
import io


def handler(event, context):
    """
    Lambda function that processes SQS messages to resize images from S3.
    Expected message format:
    {
        "bucket": "source-bucket-name",
        "key": "path/to/image.jpg",
        "width": 100,  # optional, default 200
        "height": 100  # optional, default 200
    }
    """
    sqs = boto3.client("sqs")
    s3 = boto3.client("s3")
    queue_url = os.environ["SQS_QUEUE_URL"]
    thumbnail_bucket = os.environ["THUMBNAIL_BUCKET"]

    for record in event["Records"]:
        try:
            # Parse the message
            message = json.loads(record["body"])
            source_bucket = message["bucket"]
            source_key = message["key"]
            width = message.get("width", 200)
            height = message.get("height", 200)

            # Download the image from S3
            response = s3.get_object(Bucket=source_bucket, Key=source_key)
            image_data = response["Body"].read()

            # Resize the image
            with Image.open(io.BytesIO(image_data)) as img:
                # Convert to RGB if image is in RGBA mode
                if img.mode == "RGBA":
                    img = img.convert("RGB")

                # Resize the image
                img.thumbnail((width, height), Image.LANCZOS)

                # Save the resized image to a buffer
                buffer = io.BytesIO()
                img.save(buffer, format="JPEG", quality=85)
                buffer.seek(0)

                # Generate the thumbnail key
                thumbnail_key = (
                    f"thumbnails/{os.path.splitext(source_key)[0]}_thumb.jpg"
                )

                # Upload the thumbnail to S3
                s3.put_object(
                    Bucket=thumbnail_bucket,
                    Key=os.path.basename(
                        thumbnail_key
                    ),  # Store in root of thumbnail bucket
                    Body=buffer,
                    ContentType="image/jpeg",
                )

                print(
                    f"Successfully created thumbnail for {source_key} in bucket {thumbnail_bucket}"
                )

        except Exception as e:
            print(f"Error processing message: {str(e)}")
            # You might want to send failed messages to a DLQ
            continue

    return {"statusCode": 200, "body": json.dumps("Image processing completed")}
