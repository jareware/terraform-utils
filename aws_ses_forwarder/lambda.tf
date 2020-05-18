# Lambda functions can only be uploaded as ZIP files, so we need to package our JS file into one
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.js"
  output_path = "${path.module}/lambda.zip"
}

# This defines our Lambda function
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  description      = "${var.comment_prefix}${var.email_domain}"
  function_name    = local.name_prefix
  handler          = "index.handler"
  runtime          = var.function_runtime
  timeout          = var.function_timeout
  memory_size      = var.memory_size
  role             = aws_iam_role.this.arn
  tags             = var.tags

  environment {
    variables = {
      LAMBDA_CONFIG = jsonencode({
        fromEmail      = "${var.from_name}@${var.email_domain}"
        subjectPrefix  = var.subject_prefix
        emailBucket    = aws_s3_bucket.this.id
        emailKeyPrefix = "emails/"
        forwardMapping = local.forward_mapping
      })
    }
  }
}

# Massage the inputs of our Terraform module to the format expected by the JS function
locals {
  forward_mapping = merge(
    zipmap(
      formatlist("%s@${var.email_domain}", keys(var.forward_mapping)),
      values(var.forward_mapping),
    ),
    length(var.forward_all_to) == 0
    ? {} # if there's no catch-all addresses defined, don't define the "@example.com" rule at all
    : zipmap(
      ["@${var.email_domain}"], # i.e. everything under this domain
      [var.forward_all_to],
    )
  )
  distinct_recipients = toset(flatten([var.forward_all_to, values(var.forward_mapping)]))
}
