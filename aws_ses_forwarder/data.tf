resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # If an external name_prefix wasn't provided, use the default one with a random suffix (to prevent clashes on resources that require globally unique names)
  name_prefix = var.name_prefix == "" ? "aws-ses-forwarder-${random_string.name_suffix.result}" : var.name_prefix
}

# Provides details about the current AWS region
data "aws_region" "this" {}

# Use this data source to get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized
data "aws_caller_identity" "this" {}

data "aws_route53_zone" "this" {
  name = replace(var.email_domain, "/.*?\\b([\\w-]+\\.[\\w-]+)\\.?$/", "$1") # e.g. "foo.example.com" => "example.com"
}
