# Create the S3 bucket in which the static content for the site should be hosted
resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}-content"
  tags   = var.tags

  # Add a CORS configuration, so that we don't have issues with webfont loading
  # http://www.holovaty.com/writing/cors-ie-cloudfront/
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  # Enable website hosting.
  # Note, though, that when accessing the bucket over its SSL endpoint, the index_document will not be used.
  website {
    index_document = var.default_root_object
    error_document = var.client_side_routing ? var.default_root_object : var.default_error_object # when enabled, our client-side routing should handle all URL's that don't point to a physical file on S3
  }
}

# Use a bucket policy (instead of the simpler acl = "public-read") so we don't need to always remember to upload objects with:
# $ aws s3 cp --acl public-read ...
# https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-2
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
      "Condition": {
        "StringEquals": {
          "aws:UserAgent": "${random_string.s3_read_password.result}"
        }
      }
    }
  ]
}
POLICY
}
