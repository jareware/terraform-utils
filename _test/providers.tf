# Beware: This assumes your "default" AWS profile.
provider "aws" {
  version = "~> 2.4"
  region  = "eu-central-1"
}

# Lambda@Edge and ACM, when used with CloudFront, need to be used in the US East region.
# Thus, we need a separate AWS provider for that region, which can be used with an alias.
# Make sure you customize this block to match your regular AWS provider configuration.
# https://www.terraform.io/docs/configuration/providers.html#multiple-provider-instances
provider "aws" {
  version = "~> 2.4"
  alias   = "us_east_1"
  region  = "us-east-1"
}
