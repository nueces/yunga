#############################################################################
# Variables
#############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "availability_zone" {
  type        = any # null, string
  description = "Availability Zones. If null terraform would select the first AZ from the region."
  default     = null
}

variable "default_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Project     = "Yunga",
    Environment = "dev"
    Terraform   = "true"
  }
}

#############################################################################
# VPC
#############################################################################

# TODO: Validate.
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# TODO: Validate that the subnet is part of the vpc_cidr_block.
variable "public_subnet_cidr_block" {
  type        = string
  description = "Public Subnet CIDR values"
  default     = "10.0.128.0/24"

}

# TODO: Validate that the subnet is part of the vpc_cidr_block.
variable "private_subnet_cidr_block" {
  type        = string
  description = "Private Subnet CIDR values"
  default     = "10.0.1.0/24"
}


variable "public_ingress_rules" {
  type = list(
    object({
      name        = string
      description = string
      port        = number
      cidr_ipv4   = string
  }))
  description = "Ingress Rules"
  default = [
    {
      name        = "ssh"
      description = "ssh rule"
      port        = 22
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      name        = "http"
      description = "http rule"
      port        = 80
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      name        = "https"
      description = "https rule"
      port        = 443
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]
}

variable "private_ingress_rules" {
  type = list(
    object({
      name        = string
      description = string
      port        = number
      cidr_ipv4   = string
  }))
  description = "Ingress Rules"
  default = [
    {
      name        = "ssh"
      description = "ssh rule"
      port        = 22
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      name        = "postgresql"
      description = "postgresql rule"
      port        = 5432
      cidr_ipv4   = ""
    },
    {
      name        = "node_export"
      description = "node export rule"
      port        = 9100
      cidr_ipv4   = ""
    },
    {
      name        = "prometheus"
      description = "prometheus rule"
      port        = 9090
      cidr_ipv4   = ""
    }
  ]
}


#############################################################################
# VMs
#############################################################################

variable "ami_id" {
  type        = string
  description = "AMI id for the VM. If null we would use the latest available that match the ami_filter_* variables."
  default     = null # null or any other ami like the previous ami release ex: "ami-059777dcb574d2598"
}

# Canonical, See Ownership verification in https://ubuntu.com/server/docs/cloud-images/amazon-ec2
variable "ami_filter_owner_id" {
  type        = string
  description = "Owner ID"
  default     = "099720109477"
}

# Ubuntu 22.04 LTS
variable "ami_filter_name" {
  type        = string
  description = "AMI filter name."
  default     = "ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"
}

variable "instance_types" {
  type        = map(string)
  description = "Instance types."
  default = {
    backend  = "t3a.medium"
    frontend = "t3a.micro"
  }
}

#############################################################################
