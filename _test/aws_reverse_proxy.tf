module "aws_reverse_proxy_1" {
  # Available inputs: https://github.com/futurice/terraform-utils/tree/master/aws_reverse_proxy#inputs
  source = "../aws_reverse_proxy"

  site_domain = "proxy1.${var.tld}"
  origin_url  = "https://www.futurice.com/"
}
