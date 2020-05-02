resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # If an external name_prefix wasn't provided, use the default one with a random suffix (to prevent clashes on resources that require globally unique names)
  name_prefix = var.name_prefix == "" ? "aws-lambda-cronjob-${random_string.name_suffix.result}" : var.name_prefix
}
