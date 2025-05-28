import json
import logging
from utils.helper import format_greeting

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    try:
        # Log the event and context for debugging
        logger.info(f"Event: {json.dumps(event)}")
        logger.info(f"Context: {str(vars(context))}")

        # Use the helper function from the layer
        message = format_greeting("World")
        logger.info(f"Generated message: {message}")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": message}),
        }
    except Exception as e:
        # Log the error
        logger.error(f"Error occurred: {str(e)}", exc_info=True)
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal server error", "details": str(e)}),
        }
