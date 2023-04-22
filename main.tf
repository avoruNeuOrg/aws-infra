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
    Name        = "ass5 -${var.environment}-public-route-table"
    Environment = "ass5 -${var.environment}"
  }
}


// Route Table Association - Public
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidr_list)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}


//Route
resource "aws_route" "route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}





# // EC2 Instance
# resource "aws_instance" "appServer"{
#   ami = var.ami
#   instance_type = "t2.micro"
#   key_name = "ec2"
#   associate_public_ip_address = true
#   disable_api_termination = true
#   iam_instance_profile = aws_iam_instance_profile.s3ImageBucket_profile.name
#   root_block_device {
#     delete_on_termination = true
#     volume_size = 50
#     volume_type = "gp2"
#   }
#   security_groups = [aws_security_group.WebAppSecurityGroup.id]
#   subnet_id = aws_subnet.public_subnets[0].id
#   user_data = <<-EOF
#   #!/bin/bash
#                         #################################
#                         # Configure EC2 instance script #
#                         #################################

#                         cd /home/ec2-user/webapp
#                         touch .env

#                         echo "DB_USER=csye6225" >> .env
#                         echo "DB_NAME=csye6225" >> .env
#                         echo "DB_PORT"=5432 >> .env

#                         echo "APP_PORT=${var.app_port}" >> .env
#                         echo "DB_HOSTNAME=${aws_db_instance.rds_instance.address}" >> .env
#                         echo "DB_PASSWORD=${var.db_password}" >> .env
#                         echo "AWS_BUCKET_NAME=${aws_s3_bucket.s3ImageBucket.bucket}" >> .env
#                         echo "AWS_REGION=${var.region}" >> .env
#                         pm2 start src/mainServer.js
#                         #npm run dev 
#                         pm2 save
#                         pm2 list

#                         sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#                         -a fetch-config \
#                         -m ec2 \
#                         -c file:/opt/cloudwatch-config.json \
#                         -s

#                         systemctl enable amazon-cloudwatch-agent.service
#                         systemctl start amazon-cloudwatch-agent.service


# EOF
#   tags = {
#     Name = "${var.assignment}-ec2_instance"
#   }
# }


//S3 
resource "aws_s3_bucket" "s3ImageBucket" {
  bucket = "${random_string.s3_bucket_name.id}.${var.environment}-images-s3"
  force_destroy = true
  tags = {
    Name = "${var.environment}-images-s3"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3ImageBucket_lifecycle"{
  bucket=aws_s3_bucket.s3ImageBucket.id
  rule{
    id="s3ImageBucket_lifecycle"
    filter {}
    transition {
      days=30
      storage_class="STANDARD_IA"
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3ImageBucket_encryption"{
  bucket=aws_s3_bucket.s3ImageBucket.id
  rule{
    apply_server_side_encryption_by_default{
      sse_algorithm="AES256"
    }
  }
}


resource "random_string" "s3_bucket_name" {
  length  = 5
  special = false
  upper   = false
  number  = true
  lower   = true
}


//S3 Public Access Block
resource "aws_s3_bucket_public_access_block" "s3ImageBucket_access"{
  bucket = aws_s3_bucket.s3ImageBucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  # restrict_public_buckets = true
}

//Policy
resource "aws_iam_policy" "iam_policy_imageS3Bucket_access" {
  name = "WebAppS3"
  description = "Allow EC2 to access Images S3 Bucket"
  policy =jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ImageBucket",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.s3ImageBucket.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.s3ImageBucket.id}"
      ]
    }
  ]
})
}



//Role
resource "aws_iam_role" "s3ImageBucket_role" {
  name ="EC2-CSYE6225"
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })    
}


//Attach Policy to Role
resource "aws_iam_role_policy_attachment" "iam_policy_imageS3Bucket_access"{
  role=aws_iam_role.s3ImageBucket_role.name
  policy_arn=aws_iam_policy.iam_policy_imageS3Bucket_access.arn
}


resource "aws_iam_policy_attachment" "policy_role_attach2" {
  name       = "policy_role_attach"
  roles      = [aws_iam_role.s3ImageBucket_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


//Instance Profile
resource "aws_iam_instance_profile" "s3ImageBucket_profile" {
  name = "EC2-CSYE6225"
  role = aws_iam_role.s3ImageBucket_role.name
}

//RDS Parameter Group

//RDS Instance
resource "aws_db_instance" "rds_instance"{
  allocated_storage = 10
  identifier = "csye6225"
  db_name = "csye6225"
  engine = "postgres"
  engine_version = "14.3"
  instance_class = "db.t3.micro"
  # mutli_az = false
  username = "csye6225"
  password = var.db_password  
  db_subnet_group_name = aws_db_subnet_group.private_subnet_group.name
  parameter_group_name= aws_db_parameter_group.postgres_parameter_group.name
  publicly_accessible = false
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}


resource "aws_db_subnet_group" "private_subnet_group"{
  name = "rds_private_subnet_group"
  subnet_ids= [aws_subnet.private_subnets[0].id,aws_subnet.private_subnets[1].id]
  tags={
    Name = "rds_private_subnet_group"
  }
}


//DB Security Group
resource "aws_security_group" "database_sg"{
  name="database_security_group"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "TCP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.WebAppSecurityGroup.id]
    }
}

# resource "aws_security_group_rule" "rds_ingress_egress" {
#   type              = "ingress"
#   from_port         = 5432
#   to_port           = 5432
#   protocol          = "tcp"
#   cidr_blocks       = ["aws_security_group.WebAppSecurityGroup.cidr_blocks"]
# }

resource "aws_s3_bucket_acl" "s3_acl"{
  bucket = aws_s3_bucket.s3ImageBucket.id
  acl="private"
}

//RDS Parameter Group
resource "aws_db_parameter_group" "postgres_parameter_group"{
  name="postgres-parameter-group"
  family="postgres14"
}





//Load Balancer Security Group
//DB Security Group
resource "aws_security_group" "loadBalancer_sg"{
  name="load_balancer_security_group"
  vpc_id = aws_vpc.vpc.id
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

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "WebAppSecurityGroup" {
  name        = "ass8-sg"
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
    description = "WEB-SOCKET"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    security_groups = [aws_security_group.loadBalancer_sg.id]
    # cidr_blocks = ["0.0.0.0/0"] ## FOR TESTING
  }  

  # ingress {
  #   description = "WEB-SOCKET"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   # security_groups = [aws_security_group.loadBalancer_sg.id]
  #   cidr_blocks = ["0.0.0.0/0"] ## FOR TESTING
  # }  

  //for testing purpose
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "template_launch" {
  name = "EC2_launch_template"
  block_device_mappings {
    device_name = "/dev/xvdg"
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp2"
    }
  }
  disable_api_termination = false
  iam_instance_profile {
    name = aws_iam_instance_profile.s3ImageBucket_profile.name
  }
  image_id      = var.ami
  instance_type = "t2.micro"
  key_name      = "ec2"
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnets[0].id
    security_groups             = [aws_security_group.WebAppSecurityGroup.id]

  }
  #  vpc_security_group_ids = [aws_security_group.app_sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EC2_INSTANCE"
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    DB_USER         = "${aws_db_instance.rds_instance.identifier}"
    DB_NAME         = "${aws_db_instance.rds_instance.db_name}"
    DB_PORT         = "${var.db_port}"
    APP_PORT        = "4000"
    DB_HOSTNAME     = "${aws_db_instance.rds_instance.address}"
    DB_PASSWORD     = "${var.db_password}"
    AWS_BUCKET_NAME = "${aws_s3_bucket.s3ImageBucket.bucket}"
  }))
  lifecycle {
    prevent_destroy = false
  }
}



resource "aws_autoscaling_group" "asg" {
  name             = "csye6225-asg-spring2023"
  max_size         = 3
  min_size         = 1
  desired_capacity = 1
  force_delete     = true
  default_cooldown = 60

  launch_template {
    id      = aws_launch_template.template_launch.id
    version = "$Latest"
  }
  vpc_zone_identifier = [for subnet in aws_subnet.public_subnets : subnet.id]

  target_group_arns = [aws_lb_target_group.target_group.arn]
  tag {
    key                 = "Application"
    value               = "WebApp"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}


resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scaleupalaram"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scaledownalarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}

resource "aws_lb" "lb" {
  name               = "csye6225-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadBalancer_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  #  enable_deletion_protection = false

  tags = {
    Application = "WebApp"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "csye6225-lb-alb-tg"
  port        = "4000"
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/healthz"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}


data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = "${data.aws_route53_zone.selected.name}"
#   type    = "A"
#   ttl     = "60"
#   records = [aws_instance.appServer.public_ip]
# }


resource "aws_route53_record" "server1-record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

# resource "aws_cloudwatch_log_group" "csye6225" {
#   name = "csye6225"
# }


# // Application  Security Group
# resource "aws_security_group" "WebAppSecurityGroup" {
#   name        = "ass4-sg"
#   description = "Allow inbound traffic"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "WEB-SOCKET"
#     from_port   = 4000
#     to_port     = 4000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }  

#   # ingress {
#   #   description = "TCP traffic to port anywhere"
#   #   to_port     = var.app_port
#   #   from_port   = var.app_port
#   #   protocol    = "tcp"
#   #   cidr_blocks = ["0.0.0.0/0"]
#   # }

#   //for testing purpose
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }