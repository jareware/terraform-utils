output "function_name" {
  description = "This is the unique name of the Lambda function that was created"
  value       = aws_lambda_function.this.id
}

output "function_role" {
  value       = aws_iam_role.this.name
  description = "The IAM role for the function created; can be used to attach additional policies/permissions"
}
