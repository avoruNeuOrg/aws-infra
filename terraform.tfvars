region                   = "us-east-1"
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidr_list  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidr_list = ["10.0.6.0/24", "10.0.4.0/24", "10.0.5.0/24"]
environment              = "dev"
profile                  = "default"
internet_gateway_cidr    = "0.0.0.0/0"
ami = "ami-0dfcb1ef8550277af"