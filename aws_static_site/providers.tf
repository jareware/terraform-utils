# This alias is needed because ACM is only available in the "us-east-1" region
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
