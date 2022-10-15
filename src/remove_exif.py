"""
Lambda for stripping exif data from images on S3 upload.
"""
import os
import json
import logging
import boto3
from exif import Image

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_CLIENT = boto3.client("s3")
DST_BUCCKET: str = os.environ.get("DST_BUCKET")


def remove_exif(image_file: bytes) -> bytes:
    """
    Takes an image and returns it with exif data removed.
    """
    image = Image(image_file)
    if image.has_exif:
        image.delete_all()
    return image.get_file()


def lambda_handler(event: dict, context: object):
    """
    When triggered with an event containing an image, lambda will remove exif data and store
    the image in a pre-defined bucket.
    """
    source_bucket_name: str = event["Records"][0]["s3"]["bucket"]["name"]
    image_file_name: str = event["Records"][0]["s3"]["object"]["key"]

    logger.info(
        "Invoking %s to remove exif from %s triggered by upload to %s",
        context.function_name,
        image_file_name,
        source_bucket_name,
    )

    image_file: bytes = S3_CLIENT.get_object(
        Bucket=source_bucket_name, Key=image_file_name
    )["Body"].read()

    image: bytes = remove_exif(image_file)

    S3_CLIENT.put_object(Bucket=DST_BUCCKET, Key=image_file_name, Body=image)

    response_message: str = (
        f"Successfully removed exif data from {image_file_name} "
        f"and saved to {source_bucket_name}"
    )
    logger.info(response_message)
    return {
        "statusCode": 200,
        "body": json.dumps(response_message),
    }
