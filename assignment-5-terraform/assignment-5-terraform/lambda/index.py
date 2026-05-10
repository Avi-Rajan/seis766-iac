import os
import json
import boto3
from io import BytesIO
from PIL import Image
from urllib.parse import unquote_plus

s3 = boto3.client("s3")

OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
THUMBNAIL_SIZE = (200, 200)


def handler(event, context):
    # SQS delivers messages in a Records array. Each message body is the
    # SNS notification, whose Message field contains the original S3 event.
    for sqs_record in event["Records"]:
        sns_envelope = json.loads(sqs_record["body"])
        s3_event = json.loads(sns_envelope["Message"])

        for s3_record in s3_event["Records"]:
            src_bucket = s3_record["s3"]["bucket"]["name"]
            src_key = unquote_plus(s3_record["s3"]["object"]["key"])

            print(f"Processing s3://{src_bucket}/{src_key}")

            obj = s3.get_object(Bucket=src_bucket, Key=src_key)
            img = Image.open(BytesIO(obj["Body"].read()))

            # Convert to RGB so JPEGs / PNGs / etc all save cleanly
            if img.mode != "RGB":
                img = img.convert("RGB")

            img.thumbnail(THUMBNAIL_SIZE)

            buffer = BytesIO()
            img.save(buffer, format="JPEG", quality=85)
            buffer.seek(0)

            base, _ = os.path.splitext(os.path.basename(src_key))
            out_key = f"thumbnails/{base}.jpg"

            s3.put_object(
                Bucket=OUTPUT_BUCKET,
                Key=out_key,
                Body=buffer,
                ContentType="image/jpeg",
            )

            print(f"Wrote thumbnail to s3://{OUTPUT_BUCKET}/{out_key}")

    return {"statusCode": 200}
