import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")
    return {"statusCode": 200, "body": "Success"}
