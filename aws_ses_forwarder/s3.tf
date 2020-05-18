# Create the S3 bucket in which the emails are stored
resource "aws_s3_bucket" "this" {
  bucket = local.name_prefix
  tags   = var.tags

  lifecycle_rule {
    enabled = true

    expiration {
      days = 1
    }
  }
}

# Allow SES to write incoming email to the bucket for storage
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GiveSesPermissionToWriteEmail",
      "Effect": "Allow",
      "Principal": {
        "Service": "ses.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      "Condition": {
        "StringEquals": {
          "aws:Referer": "${data.aws_caller_identity.this.account_id}"
        }
      }
    }
  ]
}
EOF
}
