terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

//VPC 
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ass3-vpc"
  }
}

// Private Subnets 
resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidr_list)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr_list[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "ass3-private-subnet-${count.index}"
  }
}

// Public Subnets 
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr_list)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_list[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "ass3-public-subnet-${count.index}"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "ass3-igw"
  }
}


// Route Table - Private 
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "ass3 -${var.environment}-private-route-table"
    Environment = "ass3 -${var.environment}"
  }
}

// Route Table Association - Private
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidr_list)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}

// Route Table - Public 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "ass3 -${var.environment}-public-route-table"
    Environment = "ass3 -${var.environment}"
  }
}


// Route Table Association - Public
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidr_list)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}



resource "aws_route" "route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}