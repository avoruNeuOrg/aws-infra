
variable "region" {
  description = "The AWS region to deploy to"
}

variable "environment" {
  description = "The Deployment environment"
}

//Networking
variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnet_cidr_list" {
  type        = list(any)
  description = "The CIDR block for the public subnet"
}

variable "private_subnet_cidr_list" {
  type        = list(any)
  description = "The CIDR block for the private subnet"
}


# variable "availability_zone" {
#   description       = "The availability zone for the subnets"
#   availability_zone = var.region
# }

variable "profile" {
  description = "The profile to use for AWS"
}

