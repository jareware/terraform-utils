# Allow our Lambda to be invoked by SES
resource "aws_lambda_permission" "ses_forwarding_function_policy" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.arn
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.this.account_id
}

# Allow Lambda to invoke our functions
resource "aws_iam_role" "this" {
  name = local.name_prefix
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Allow our Lambda to manage email in the S3 bucket, and send it via SES
resource "aws_iam_policy" "this" {
  name   = local.name_prefix
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ses:SendRawEmail",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
    }
  ]
}
EOF
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
