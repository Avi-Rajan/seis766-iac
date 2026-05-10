output "input_bucket" {
  value = aws_s3_bucket.input.bucket
}

output "output_bucket" {
  value = aws_s3_bucket.output.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.image_uploads.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.thumbnail.url
}

output "lambda_function_name" {
  value = aws_lambda_function.thumbnail.function_name
}
