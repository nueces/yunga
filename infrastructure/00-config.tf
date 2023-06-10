terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }

  backend "s3" {
    bucket = "887012142425-eu-central-1-terraform-backend-yunga"
    key    = "infrastructure.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project     = "Yunga"
      Environment = "dev"
      Terraform   = "true"
    }
  }
}

# Load project wide configuration
locals {
  configuration = yamldecode(file(join("/", [path.root, "..", "configuration.yml"])))
  vault_path    = join("/", [path.root, "..", local.configuration.vault_path])
  defaults = {
    availability_zone = coalesce(var.availability_zone, element(data.aws_availability_zones.current.names, 0))
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "current" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

output "aws" {
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    defaults   = local.defaults
  }
}

