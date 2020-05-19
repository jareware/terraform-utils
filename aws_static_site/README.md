# aws_static_site

This module implements a website for hosting static content.

Main features:

- DNS entries are created automatically
- S3 bucket is created automatically
- HTTPS enabled by default
- HTTP Strict Transport Security supported
- Direct access to the S3 bucket is prevented

Optional features:

- HTTP Basic Auth
- Plain HTTP instead of HTTPS
- Cache TTL overrides
- Custom response headers sent to clients

Resources used:

- Route53 for DNS entries
- ACM for SSL certificates
- CloudFront for proxying requests
- Lambda@Edge for transforming requests
- IAM for permissions

## About CloudFront operations

This module manages CloudFront distributions, and these operations are generally very slow. Your `terraform apply` may take anywhere from a few minutes **up to 45 minutes** (if you're really unlucky). Be patient: if they start successfully, they almost always finish successfully, it just takes a while.

Additionally, this module uses Lambda@Edge functions with CloudFront. Because Lambda@Edge functions are replicated, [they can't be deleted immediately](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-delete-replicas.html). This means a `terraform destroy` won't successfully remove all resources on its first run. It should complete successfully when running it again after a few hours, however.

## Example 1: Simple static site

Assuming you have the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html) set up, and a DNS zone for `example.com` configured on Route 53:

```tf
# Lambda@Edge and ACM, when used with CloudFront, need to be used in the US East region.
# Thus, we need a separate AWS provider for that region, which can be used with an alias.
# Make sure you customize this block to match your regular AWS provider configuration.
# https://www.terraform.io/docs/configuration/providers.html#multiple-provider-instances
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "my_site" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_static_site#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v13.0...master
  source    = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_static_site?ref=v13.0"
  providers = { aws.us_east_1 = aws.us_east_1 } # this alias is needed because ACM is only available in the "us-east-1" region

  site_domain = "hello.example.com"
}

resource "aws_s3_bucket_object" "my_index" {
  bucket       = module.my_site.bucket_name
  key          = "index.html"
  content      = "<pre>Hello World!</pre>"
  content_type = "text/html; charset=utf-8"
}

output "bucket_name" {
  description = "The name of the S3 bucket that's used for hosting the content"
  value       = module.my_site.bucket_name
}
```

After `terraform apply` (which may take a long time), you should be able to visit `hello.example.com`, be redirected to HTTPS, and be greeted by the above `Hello World!` message.

You may (and probably will) want to upload more files into the bucket outside of Terraform. Using the official [AWS CLI](https://aws.amazon.com/cli/) this could look like:

```bash
aws s3 cp --cache-control=no-store,must-revalidate image.jpg "s3://$(terraform output bucket_name)/"
```

After this, `image.jpg` will be available at `https://hello.example.com/image.jpg`.

## Example 2: Basic Authentication

This module supports password-protecting your site with HTTP Basic Authentication, via a Lambda@Edge function.

Update the `my_site` module in Example 1 as follows:

```tf
module "my_site" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_static_site#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v13.0...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_static_site?ref=v13.0"

  site_domain = "hello.example.com"

  basic_auth_username = "admin"
  basic_auth_password = "secret"
}
```

After `terraform apply` (which may take a long time), visiting `hello.example.com` should pop out the browser's authentication dialog, and not let you proceed without the above credentials.

## Example 3: Custom response headers

This module supports injecting custom headers into CloudFront responses, via a Lambda@Edge function.

By default, the function only adds `Strict-Transport-Security` headers (as it [significantly improves security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security#An_example_scenario) with HTTPS), but you may need other customization.

For [additional security hardening of your static site](https://aws.amazon.com/blogs/networking-and-content-delivery/adding-http-security-headers-using-lambdaedge-and-amazon-cloudfront/), including a fairly-draconian (and thoroughly-documented) [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP), update the `my_site` module in Example 1 as follows:

```tf
module "my_site" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_static_site#inputs
  # Check for updates: https://github.com/futurice/terraform-utils/compare/v13.0...master
  source = "git::ssh://git@github.com/futurice/terraform-utils.git//aws_static_site?ref=v13.0"

  site_domain = "hello.example.com"

  add_response_headers = {

    # Add basic security headers:
    Strict-Transport-Security = "max-age=31536000" # the page should ONLY be accessed using HTTPS, instead of using HTTP (max-age == one year)
    X-Content-Type-Options    = "nosniff"          # the MIME types advertised in the Content-Type headers should ALWAYS be followed; this allows to opt-out of MIME type sniffing
    X-Frame-Options           = "DENY"             # disallow rendering the page inside a frame; besides legacy browsers, superseded by CSP
    X-XSS-Protection          = "1; mode=block"    # stops pages from loading when they detect reflected cross-site scripting (XSS) attacks; besides legacy browsers, superseded by CSP
    Referrer-Policy           = "same-origin"      # a referrer will be sent for same-site origins, but cross-origin requests will send no referrer information

    # Remove some headers which could disclose details about our upstream server
    # Note that not all headers can be altered by Lambda@Edge: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-header-restrictions
    Server                 = "" # "Server" header can't be removed, but this will reset it to "CloudFront"
    X-Amz-Error-Code       = ""
    X-Amz-Error-Message    = ""
    X-Amz-Error-Detail-Key = ""
    X-Amz-Request-Id       = ""
    X-Amz-Id-2             = ""

    # Add CSP header:
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
    Content-Security-Policy = replace(replace(replace(<<-EOT

      default-src # serves as a fallback for the other CSP fetch directives; for many of the following directives, if they are absent, the user agent will look for the default-src directive and will use this value for it
        'none' # by default, don't allow anything; we'll specifically white-list things below
        ;
      block-all-mixed-content # prevents loading any assets using HTTP when the page is loaded using HTTPS
        ;
      connect-src # restricts the URLs which can be loaded using script interfaces (e.g. XHR, WebSocket)
        api.example.com # allow connecting to this specific API (not not others!)
        ;
      form-action # restricts the URLs which can be used as the target of a form submission
        'none' # for better or worse, most forms today are JavaScript-only -> we can prohibit all normal form submission
        ;
      img-src # specifies valid sources of images and favicons
        'self' # allow regular images that ship with the UI
        data: # allow small assets which have been inlined by webpack
        ;
      font-src # specifies valid sources of webfonts
        'self' # allow loading self-hosted fonts; add e.g. fonts.googleapis.com here (without any quotes!) to allow loading Google Fonts (https://fonts.google.com/)
        ;
      manifest-src # specifies which manifest can be applied to the resource
        'self' # our manifest is always on our own domain
        ;
      navigate-to # restricts the URLs to which a document can initiate navigations by any means including <form> (if form-action is not specified), <a>, window.location, window.open, etc
        'self' # allow navigating within our own site, but not anywhere else
        ;
      prefetch-src # specifies valid resources that may be prefetched or prerendered
        'none' # we don't currently have any <link rel="prefetch" /> or the like -> prohibit until we do
        ;
      script-src # specifies valid sources for JavaScript; this includes not only URLs loaded directly into <script> elements, but also things like inline script event handlers (onclick) and XSLT stylesheets which can trigger script execution
        'self' # allow only our own scripts
        ;
      script-src-attr # specifies valid sources for JavaScript inline event handlers; this includes only inline script event handlers like onclick, but not URLs loaded directly into <script> elements
        'none' # we don't use any inline event handlers, only proper <script> elements -> prohibit them all
        ;
      style-src # specifies valid sources for stylesheets
        'self' # allow our own CSS bundle; sadly, you also need 'unsafe-inline' for most CSS-in-JS solutions to work (e.g. https://styled-components.com/)
        ;
      style-src-attr # specifies valid sources for inline styles applied to individual DOM elements
        'none' # we don't currently use any -> prohibit them all
        ;
      frame-src # specifies valid sources for nested browsing contexts loading using elements such as <frame> and <iframe>
        'none' # don't allow us to be framed
        ;

    EOT
    , "/#.*/", " "), "/[ \n]+/", " "), " ;", ";") # strip out comments and newlines, and collapse consecutive whitespace so the end-result looks pleasant
  }
}
```

After `terraform apply` (which may take a long time), visiting `hello.example.com` should give you these extra headers (and hide some upstream headers that were originally present).

## How CloudFront caching works

It's important to understand how CloudFront caches the files it proxies from S3. Because this module is built on the `aws_reverse_proxy` module, [everything its documentation says about CloudFront caching](../aws_reverse_proxy#how-cloudfront-caching-works) is relevant here, too.

### Specifying cache lifetimes on S3

It's a good idea to specify cache lifetimes for files individually, as they are uploaded.

For example, to upload a file so that **it's never cached by CloudFront**:

```bash
aws s3 cp --cache-control=no-store,must-revalidate index.html "s3://$(terraform output bucket_name)/"
```

Alternatively, to upload a file so that **CloudFront can cache it forever**:

```bash
aws s3 cp --cache-control=max-age=31536000 static/image-v123.jpg "s3://$(terraform output bucket_name)/"
```

Learn more about [effective caching strategies on CloudFront](../aws_reverse_proxy#specifying-cache-lifetimes-on-the-origin).

<!-- terraform-docs:begin -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| site_domain | Domain on which the static site will be made available (e.g. `"www.example.com"`) | `any` | n/a | yes |
| name_prefix | Name prefix to use for objects that need to be created (only lowercase alphanumeric characters and hyphens allowed, for S3 bucket name compatibility) | `string` | `""` | no |
| comment_prefix | This will be included in comments for resources that are created | `string` | `"Static site: "` | no |
| cloudfront_price_class | CloudFront price class to use (`100`, `200` or `"All"`, see https://aws.amazon.com/cloudfront/pricing/) | `number` | `100` | no |
| viewer_https_only | Set this to `false` if you need to support insecure HTTP access for clients, in addition to HTTPS | `bool` | `true` | no |
| cache_ttl_override | When >= 0, override the cache behaviour for ALL objects in S3, so that they stay in the CloudFront cache for this amount of seconds | `number` | `-1` | no |
| default_root_object | The object to return when the root URL is requested | `string` | `"index.html"` | no |
| default_error_object | The object to return when an unknown URL is requested | `string` | `"error.html"` | no |
| client_side_routing | When enabled, every request that doesn't match a static file in the bucket will get rewritten to the index file; this allows you to handle routing fully in client-side JavaScript | `bool` | `false` | no |
| add_response_headers | Map of HTTP headers (if any) to add to outgoing responses before sending them to clients | `map` | `{}` | no |
| hsts_max_age | How long should `Strict-Transport-Security` remain in effect for the site; disabled automatically when `viewer_https_only = false` | `number` | `31557600` | no |
| basic_auth_username | When non-empty, require this username with HTTP Basic Auth | `string` | `""` | no |
| basic_auth_password | When non-empty, require this password with HTTP Basic Auth | `string` | `""` | no |
| basic_auth_realm | When using HTTP Basic Auth, this will be displayed by the browser in the auth prompt | `string` | `"Authentication Required"` | no |
| basic_auth_body | When using HTTP Basic Auth, and authentication has failed, this will be displayed by the browser as the page content | `string` | `"Unauthorized"` | no |
| lambda_logging_enabled | When true, writes information about incoming requests to the Lambda function's CloudWatch group | `bool` | `false` | no |
| tags | AWS Tags to add to all resources created (where possible); see https://aws.amazon.com/answers/account-management/aws-tagging-strategies/ | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | The name of the S3 bucket that's used for hosting the content |
| reverse_proxy | CloudFront-based reverse-proxy that's used for performance, access control, etc |
| bucket_domain_name | Full S3 domain name for the bucket used for hosting the content (e.g. `"aws-static-site.s3-website.eu-central-1.amazonaws.com"`) |
<!-- terraform-docs:end -->
