terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket  = "cm-sdg-terraform-state-bucket"
    key     = "sdg/caddy/main/terraform.tfstate"
    region  = "us-east-1"
    profile = "demo"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "demo"
}
