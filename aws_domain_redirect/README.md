# aws_domain_redirect

Creates the necessary resources on AWS to implement an HTTP redirect from a domain (e.g. `redir.example.com`) to a given URL (e.g. `https://www.futurice.com/careers/women-who-code-helsinki`). Useful for creating human-friendly shortcuts for deeper links into a site, or for dynamic links (e.g. `download.example.com` always pointing to your latest release).

Implementing this on AWS actually requires quite a few resources:

- DNS records on [Route 53](https://aws.amazon.com/route53/)
- A [CloudFront](https://aws.amazon.com/cloudfront/) distribution for SSL termination, for allowing secure redirection over HTTPS
- An SSL certificate for the distribution from [ACM](https://aws.amazon.com/certificate-manager/)
- An [S3](https://aws.amazon.com/s3/) bucket with the relevant [redirect rules](https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html#advanced-conditional-redirects)

Luckily, this module encapsulates this configuration quite neatly.

## Example

Assuming you have the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html) set up, and a DNS zone for `example.com` configured on Route 53:

```tf
# "To use an ACM Certificate with CloudFront, you must request or import the certificate in the US East (N. Virginia) region."
# https://docs.aws.amazon.com/acm/latest/userguide/acm-services.html
# https://www.terraform.io/docs/configuration/providers.html#multiple-provider-instances
provider "aws" {
  alias                   = "acm_provider" # the aws_domain_redirect module expects an "aws" provider with this alias to be present
  shared_credentials_file = "./aws.key"    # make sure you customize this to match your regular AWS provider config
  region                  = "us-east-1"    # this is the important bit, due to the aforementioned limitation of AWS regions and ACM
}

module "my_redirect" {
  # Check for updates at: https://github.com/futurice/terraform-utils/compare/v3.0...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_domain_redirect?ref=v3.0"

  redirect_domain = "go.example.com"
  redirect_url    = "https://www.futurice.com/careers/"
}
```

Applying this **will take a very long time**, because both ACM and especially CloudFront are quite slow to update. After that, both `http://go.example.com` and `https://go.example.com` should redirect clients to `https://www.futurice.com/careers/`.