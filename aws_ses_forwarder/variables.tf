variable "email_domain" {
  description = "Domain on which the email forwarding should be set up (e.g. `\"example.com\"`)"
}

variable "name_prefix" {
  description = "Name prefix to use for objects that need to be created (only lowercase alphanumeric characters and hyphens allowed, for S3 bucket name compatibility)"
  default     = ""
}

variable "comment_prefix" {
  description = "This will be included in comments for resources that are created"
  default     = "SES Forwarder: "
}

variable "from_name" {
  description = "Mailbox name from which forwarded emails are sent"
  default     = "noreply"
}

variable "subject_prefix" {
  description = "Text to prepend to the subject of each email before forwarding it (e.g. `\"Forwarded: \"`)"
  default     = ""
}

variable "forward_all_to" {
  description = "List of addesses to which ALL incoming email should be forwarded"
  type        = list(string)
  default     = []
}

variable "forward_mapping" {
  description = "Map defining receiving mailboxes, and to which addesses they forward their incoming email; takes precedence over `forward_all_to`"
  type        = map(list(string))
  default     = {}
}

variable "rule_set_name" {
  description = "Name of the externally provided SES Rule Set, if you want to manage it yourself"
  default     = ""
}

variable "function_timeout" {
  description = "The amount of time our Lambda Function has to run in seconds"
  default     = 10
}

variable "memory_size" {
  description = "Amount of memory in MB our Lambda Function can use at runtime"
  default     = 128
}

variable "function_runtime" {
  description = "Which node.js version should Lambda use for our function"
  default     = "nodejs12.x"
}

variable "tags" {
  description = "AWS Tags to add to all resources created (where possible); see https://aws.amazon.com/answers/account-management/aws-tagging-strategies/"
  type        = map(string)
  default     = {}
}
