# Configure terraform instance
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
  required_version = "~> 1.1.7"

  # Note: these resources are manually created per TF site
  # https://www.terraform.io/docs/language/settings/backends/s3.html
  
  backend "s3" {
    bucket         = "REDACTED" # Redacted for the sake of this example.
    key            = "REDACTED" # Redacted for the sake of this example.
    region         = "REDACTED" # Redacted for the sake of this example.
    access_key     = "REDACTED" # Redacted for the sake of this example.
    secret_key     = "REDACTED" # Redacted for the sake of this example.
    dynamodb_table = "REDACTED" # Redacted for the sake of this example.
  }
}

provider "aws" {
  region = var.region
}
