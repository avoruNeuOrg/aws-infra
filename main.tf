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
    Name = "ass-vpc"
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
    Name = "ass-private-subnet-${count.index}"
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
    Name = "ass-public-subnet-${count.index}"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "ass-igw"
  }
}


// Route Table - Private 
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "ass -${var.environment}-private-route-table"
    Environment = "ass -${var.environment}"
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



resource "aws_security_group" "sg_ingressRules" {
  name        = "ass4-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WEB-SOCKET"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}


resource "aws_instance" "appServer"{
  ami = var.ami
  instance_type = "t2.micro"
  key_name = "ec2"
  associate_public_ip_address = true
  disable_api_termination = true
  root_block_device {
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }
  security_groups = [aws_security_group.sg_ingressRules.id]
  subnet_id = aws_subnet.public_subnets[0].id
}
