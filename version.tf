terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.58.0"
    }
    random = {
      version = ">= 3.4.3"
    }
  }
}
