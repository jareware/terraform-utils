# Based on: https://www.terraform.io/docs/providers/aws/guides/serverless-with-aws-lambda-and-api-gateway.html
# See also: https://github.com/hashicorp/terraform/issues/10157
# See also: https://github.com/carrot/terraform-api-gateway-cors-module/

# This defines our Lambda function
resource "aws_lambda_function" "this" {

  # When invoked with a local zipfile:
  filename         = var.function_s3_bucket == "" ? var.function_zipfile : null
  source_code_hash = var.function_s3_bucket == "" ? var.function_s3_bucket == "" ? filebase64sha256(var.function_zipfile) : "" : null

  # When invoked with a zipfile in S3:
  s3_bucket = var.function_s3_bucket == "" ? null : var.function_s3_bucket
  s3_key    = var.function_s3_bucket == "" ? null : var.function_zipfile

  # These are the same for both deployment methods:
  description   = "${var.comment_prefix}${var.api_domain}"
  function_name = local.name_prefix
  handler       = var.function_handler
  runtime       = var.function_runtime
  timeout       = var.function_timeout
  memory_size   = var.memory_size
  role          = aws_iam_role.this.arn
  tags          = var.tags

  environment {
    variables = var.function_env_vars
  }
}
