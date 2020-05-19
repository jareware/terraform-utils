# aws_ses_forwarder

This module implements a simple, serverless email forwarding service for your custom domain.

Main features:

- MX records for email routing are created automatically
- DKIM records are set up to improve deliverability
- Automatic verification of recipient emails

Optional features:

- Custom "From" address for forwarded emails
- Custom prefix added to "Subject" fields of forwarded emails
- Skipping recipient verification when [out of the SES Sandbox](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html)

Resources used:

- Route53 for DNS entries
- S3 for temporary email storage
- Lambda for performing email routing
- SES for email ingress and egress
- IAM for permissions

The JavaScript code used on the Lambda is based on the excellent [`aws-lambda-ses-forwarder`](https://github.com/arithmetric/aws-lambda-ses-forwarder) library.

## SES Sandbox limits

By default, to discourage spammers, SES will limit you to forwarding **at most 200 emails per a 24 hour period** (or 1 email per second).

To go beyond these limits, you need to [request a service limit increase from AWS](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html).

## Example 1: Simple forwarding

Assuming you have the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html) set up, and a DNS zone for `example.com` configured on Route 53:

```tf
module "my_email_forwarder" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_ses_forwarder#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v12.1...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_ses_forwarder?ref=v12.1"

  email_domain   = "example.com"
  forward_all_to = ["john.doe@futurice.com"]
}
```

After `terraform apply`, SES will send a verification email to all recipient emails you included. Each recipient must click on the verification link in that email before they start receiving forwarded emails. This is a feature of [the SES Sandbox](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html), and you can get rid of it by contacting AWS support (and then setting `skip_recipient_verification` to `true`).

Once the emails are verified, drop an email to `whatever@example.com`, and it should pop into the inbox of `john.doe@futurice.com`.

## Example 2: Forwarding specific mailboxes

You can also have specific mailboxes forward email to specific addresses:

```tf
module "my_email_forwarder" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_ses_forwarder#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v12.1...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_ses_forwarder?ref=v12.1"

  email_domain = "example.com"

  forward_mapping = {
    sales = ["alice@futurice.com"]
    admin = ["bob@futurice.com"]
  }
}
```

Once applied, and recipients verified:

- Emails sent to `sales@example.com` are forwarded to `alice@futurice.com`
- Emails sent to `admin@example.com` are forwarded to `bob@futurice.com`

This can be combined with `forward_all_to`, so that instead of getting a bounce for sending email to a non-existent mailbox, those emails also get forwarded somewhere.

## Example 3: Multiple instances

Due to the way AWS SES works, [there can be only one active receipt rule set at a time](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/receiving-email-managing-receipt-rule-sets.html#receiving-email-managing-receipt-rule-sets-enable-disable). Normally this module manages the rule set for you, and you don't need to care. But if you need to use the module multiple times (say, for several domains), they can't both have their rule sets be the active one, and you need to manage the rule set yourself:

```tf
resource "aws_ses_receipt_rule_set" "forwarding" {
  rule_set_name = "my-forwarding-rules"
}

resource "aws_ses_active_receipt_rule_set" "forwarding" {
  rule_set_name = aws_ses_receipt_rule_set.forwarding.rule_set_name
}

module "my_email_forwarder" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_ses_forwarder#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v12.1...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_ses_forwarder?ref=v12.1"

  rule_set_name  = aws_ses_receipt_rule_set.forwarding.rule_set_name
  email_domain   = "example.com"
  forward_all_to = ["john.doe@futurice.com"]
}

module "other_email_forwarder" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_ses_forwarder#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v12.1...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_ses_forwarder?ref=v12.1"

  rule_set_name  = aws_ses_receipt_rule_set.forwarding.rule_set_name
  email_domain   = "example.org"
  forward_all_to = ["john.doe@futurice.com"]
}
```

<!-- terraform-docs:begin -->

<!-- terraform-docs:end -->
