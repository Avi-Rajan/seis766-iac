terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "input" {
  bucket        = "${var.project_name}-input-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-input"
  }
}

resource "aws_s3_bucket" "output" {
  bucket        = "${var.project_name}-output-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-output"
  }
}

resource "aws_sns_topic" "image_uploads" {
  name = "${var.project_name}-uploads"

  tags = {
    Name = "${var.project_name}-uploads"
  }
}

resource "aws_sns_topic_policy" "allow_s3_publish" {
  arn = aws_sns_topic.image_uploads.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.image_uploads.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_s3_bucket.input.arn }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "input_to_sns" {
  bucket = aws_s3_bucket.input.id

  topic {
    topic_arn = aws_sns_topic.image_uploads.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.allow_s3_publish]
}

resource "aws_sqs_queue" "thumbnail_dlq" {
  name                      = "${var.project_name}-thumbnail-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name = "${var.project_name}-thumbnail-dlq"
  }
}

resource "aws_sqs_queue" "thumbnail" {
  name                       = "${var.project_name}-thumbnail"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.thumbnail_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${var.project_name}-thumbnail"
  }
}

resource "aws_sqs_queue_policy" "allow_sns_send" {
  queue_url = aws_sqs_queue.thumbnail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.thumbnail.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.image_uploads.arn }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "thumbnail_sub" {
  topic_arn = aws_sns_topic.image_uploads.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.thumbnail.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_inline" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.thumbnail.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.input.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.output.arn}/*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "thumbnail" {
  function_name    = "${var.project_name}-thumbnail"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 512

  layers = ["arn:aws:lambda:${var.aws_region}:770693421928:layer:Klayers-p312-Pillow:9"]

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
    }
  }

  tags = {
    Name = "${var.project_name}-thumbnail"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.thumbnail.arn
  function_name    = aws_lambda_function.thumbnail.arn
  batch_size       = 5
}
