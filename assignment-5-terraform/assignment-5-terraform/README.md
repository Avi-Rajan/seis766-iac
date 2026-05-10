
Implements the SNS fan-out pattern for image processing on AWS.


```
User upload
    │
    ▼
S3 (input bucket) ──ObjectCreated──▶ SNS topic ──▶ SQS queue ──▶ Lambda ──▶ S3 (output bucket)
                                                       │
                                                       └─▶ DLQ (after 5 failed receives)
```
