import json
from faker import Faker

fake = Faker()


def lambda_handler(event, context):
    # Generate fake user data
    user_data = {
        "name": fake.name(),
        "email": fake.email(),
        "address": fake.address(),
        "job": fake.job(),
        "company": fake.company(),
        "phone_number": fake.phone_number(),
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(user_data),
    }
