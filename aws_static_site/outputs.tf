output "bucket_name" {
  description = "The name of the S3 bucket that's used for hosting the content"
  value       = aws_s3_bucket.this.id
}

output "reverse_proxy" {
  description = "CloudFront-based reverse-proxy that's used for performance, access control, etc"
  value       = module.aws_reverse_proxy
}

output "bucket_domain_name" {
  description = "Full S3 domain name for the bucket used for hosting the content (e.g. `\"aws-static-site.s3-website.eu-central-1.amazonaws.com\"`)"
  value       = "http://${aws_s3_bucket.this.website_endpoint}/"
}
