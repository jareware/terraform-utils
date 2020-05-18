output "function_name" {
  description = "This is the unique name of the Lambda function that was created"
  value       = aws_lambda_function.this.id
}
