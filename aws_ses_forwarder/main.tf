# Add our domain to SES
resource "aws_ses_domain_identity" "this" {
  domain = var.email_domain
}

# Perform verification via DNS record, proving to SES we have ownership of the domain
resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_amazonses.${var.email_domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.this.verification_token}"]
}

# Create DNS records telling email servers SES handles the incoming email for our domain
resource "aws_route53_record" "mx_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.email_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.this.name}.amazonaws.com"]
}

# Because we assume we're in the SES sandbox, generate a verification for each email address to which we want to forward mail
resource "aws_ses_email_identity" "recipient" {
  for_each = var.skip_recipient_verification ? toset([]) : local.distinct_recipients
  email    = each.value
}

# Create a new SES rule set (only one can be active at a time, though)
resource "aws_ses_receipt_rule_set" "this" {
  count         = var.rule_set_name == "" ? 1 : 0
  rule_set_name = local.name_prefix
}

# Ensure our rule set is the active one
resource "aws_ses_active_receipt_rule_set" "this" {
  count         = var.rule_set_name == "" ? 1 : 0
  rule_set_name = var.rule_set_name == "" ? aws_ses_receipt_rule_set.this[0].rule_set_name : var.rule_set_name
}

# Configure actions SES should take when email comes in
# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/receiving-email-receipt-rules.html#receiving-email-receipt-rules-set-up
resource "aws_ses_receipt_rule" "store" {
  name          = local.name_prefix
  rule_set_name = var.rule_set_name == "" ? aws_ses_receipt_rule_set.this[0].rule_set_name : var.rule_set_name
  recipients    = [var.email_domain] # i.e. match all mailboxes on this domain
  enabled       = true
  scan_enabled  = true

  # First, store the email into S3
  s3_action {
    bucket_name       = aws_s3_bucket.this.id
    object_key_prefix = "emails/"
    position          = 1
  }

  # Then, invoke the Lambda to forward it
  lambda_action {
    function_arn    = aws_lambda_function.this.arn
    invocation_type = "Event"
    position        = 2
  }
}

# Set up DKIM for our domain, to improve deliverability
resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

# Publish the DKIM public key info on our DNS
resource "aws_route53_record" "example_amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${var.email_domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}
