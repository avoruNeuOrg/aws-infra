
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


variable "ami"{
  description = "The AMI to use for the EC2 instance"
}

variable "internet_gateway_cidr"{
  description = "The CIDR block for the internet gateway"
}

variable "db_password"{
  description = "The password for the database"
}

variable "assignment"{
  description = "The assignment name"  
}

variable "app_port"{
  description = "The port the application is running on"
}