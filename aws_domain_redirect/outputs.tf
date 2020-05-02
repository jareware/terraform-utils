output "reverse_proxy" {
  description = "CloudFront-based reverse-proxy that's used for implementing the redirect"
  value       = module.aws_reverse_proxy
}
