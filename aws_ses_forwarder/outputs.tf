output "function_name" {
  description = "This is the unique name of the Lambda function that was created"
  value       = aws_lambda_function.this.id
}

output "forward_mapping" {
  description = "Map defining receiving email addresses, and to which addesses they forward their incoming email"
  value       = local.forward_mapping
}

output "distinct_recipients" {
  description = "Distinct recipient addresses mentioned in `forward_mapping`"
  value       = local.distinct_recipients
}
