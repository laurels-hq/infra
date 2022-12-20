# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "region" {
  description = "The AWS region to provision resources in."
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "The VPC master CIDR."
  type        = map(string)
  # Recommend a /16 size = 65k IPs
  # See https://www.tunnelsup.com/subnet-calculator/
  default = {
    prod = "10.1.0.0/16"
    dev  = "10.0.0.0/16"
  }
}

variable "vpc_subnet_netbits" {
  description = "The offset from the master CIDR."
  type        = string
  # number of bits to add to the master CIDR
  # Value of "4" on a /16 results in a /20
  default = "4"
}

variable "name" {
  description = "The name of the service being deployed."
  type        = string
  default     = "laurels"
}

variable "stage" {
  description = "The stage for the resources (dev, stage, prod, etc)."
  type        = map(string)
  default = {
    prod = "prod"
    dev  = "dev"
  }
}

variable "docker_listen_port" {
  description = "The port which the service listens on in Docker."
  type        = string
  default     = "3000"
}

variable "certificate_arn" {
  description = "The ACM certificate ARN."
  type        = string
  default     = "REDACTED" # Redacted for the sake of this example.
}

variable "default_sender_email" {
  description = "The email address all emails should be sent from."
  type        = map(string)
  default = {
    prod = "\"Laurels\" <noreply@getlaurels.com>"
    dev  = "\"Laurels Dev\" <noreply@getlaurels.com>"
  }
}

variable "mixpanel_token" {
  description = "Mixpanel analytics project token."
  type        = map(string)
  default = {
    prod = "REDACTED" # Redacted for the sake of this example.
    dev  = "REDACTED" # Redacted for the sake of this example.
  }
}

variable "backoffice_email" {
  description = "The email address to which internal notifications are sent."
  type        = map(string)
  default = {
    prod = "REDACTED" # Redacted for the sake of this example.
    dev  = "REDACTED" # Redacted for the sake of this example.
  }
}

variable "base_url" {
  description = "The base URL of the application."
  type        = map(string)
  default = {
    prod = "https://getlaurels.com"
    dev  = "REDACTED" # Redacted for the sake of this example.
  }
}

variable "intercom_secret" {
  description = "The secret to enable intercom identity verification. For more info: https://www.intercom.com/help/en/articles/183-enable-identity-verification-for-web-and-mobile."
  type        = string
  default     = "REDACTED" # Redacted for the sake of this example.
}
